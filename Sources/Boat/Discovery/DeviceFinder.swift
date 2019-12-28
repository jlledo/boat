import Foundation
import Network
import Promises
import Socket

struct DeviceFinder {
    let target: SSDPSearchTarget

    let friendlyName: String

    let socketProvider: SocketProviderProtocol.Type

    private func multicastSearchRequest(responseTCPPort: Int?) -> SSDPMulticastSearchRequest {
        SSDPMulticastSearchRequest(
            target: self.target,
            responseTCPPort: responseTCPPort,
            friendlyName: self.friendlyName,
            uuid: nil
        )
    }

    init(
        target: SSDPSearchTarget,
        friendlyName: String,
        socketProvider: SocketProviderProtocol.Type = SocketProvider.self
    ) {
        self.target = target
        self.friendlyName = friendlyName
        self.socketProvider = socketProvider
    }

    private func searchV1() -> Promise<URL> {
        // Dispatch on global queue to avoid waiting on Main thread in readDatagram(into:)
        return Promise(on: .global()) { fulfill, reject in
            // Create socket
            let socket = try self.socketProvider.create(family: .inet, type: .datagram, proto: .udp)
            defer {
                socket.close()
            }

            // Send query to SSDP multicast address
            let searchRequest = self.multicastSearchRequest(responseTCPPort: nil)

            let destinationSocketAddress = Socket.createAddress(for: "239.255.255.250", on: 1900)!
            try socket.write(from: searchRequest.ssdpEncoded(), to: destinationSocketAddress)

            // Read response
            var searchResponseData = Data()
            _ = try socket.readDatagram(into: &searchResponseData)

            // Decode response
            let response = try SSDPSearchResponseV1(from: searchResponseData)

            fulfill(response.location)
        }.timeout(1.5)
    }

    private func searchV2() -> Promise<URL> {
        let descriptionURLPromise = Promise<URL>.pending().timeout(2)

        var listener: NWListener?
        do {
            listener = try NWListener(using: .tcp)
        } catch {
            descriptionURLPromise.reject(error)
        }

        listener?.newConnectionHandler = { newConnection in
            newConnection.start(queue: .global())
            newConnection.receiveMessage { data, _, _, error in
                guard error == nil else {
                    descriptionURLPromise.reject(error!)
                    return
                }
                do {
                    let response = try SSDPSearchResponseV2(from: data)
                    descriptionURLPromise.fulfill(response.location)
                } catch let discoveryError {
                    descriptionURLPromise.reject(discoveryError)
                }
            }
        }

        let listenerPortPromise = Promise<Int>.pending().timeout(1)
        listener?.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                listenerPortPromise.fulfill(Int(listener!.port!.rawValue))
            case .failed(let error):
                listenerPortPromise.reject(error)
            default:
                break
            }
        }

        listenerPortPromise.then { listenerPort in
            let requestConnection = NWConnection(
                host: NWEndpoint.Host("239.255.255.250"),
                port: NWEndpoint.Port(1900),
                using: .udp
            )

            requestConnection.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    let searchRequest = self.multicastSearchRequest(responseTCPPort: listenerPort)
                    requestConnection.send(
                        content: searchRequest.ssdpEncoded(),
                        completion: .idempotent
                    )

                    requestConnection.cancel()

                default:
                    break
                }
            }
            requestConnection.start(queue: .global())
        }

        listener?.start(queue: .global())

        return descriptionURLPromise
    }

    func search() -> Promise<URL> {
        race([searchV2(), searchV1()])
    }

    var gatewayDescriptionURL: Promise<URL> {
        return search()
    }
}
