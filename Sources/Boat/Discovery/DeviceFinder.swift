import Foundation
import Network
import Promises
import Socket

struct DeviceFinder {
    let target: SSDPSearchTarget

    let friendlyName: String

    let socketProvider: SocketProviderProtocol.Type

    private func searchRequest(host: Socket.Address, responseTCPPort: Int?) -> SSDPSearchRequest {
        SSDPSearchRequest(
            host: host,
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

    func search(at address: Socket.Address = .ssdpMulticast) -> Promise<URL> {
        // Dispatch on global queue to avoid waiting on Main thread in readDatagram(into:)
        return Promise(on: .global()) { fulfill, reject in
            // Create socket
            let socket = try self.socketProvider.create(family: .inet, type: .datagram, proto: .udp)
            defer {
                socket.close()
            }

            // Send query to SSDP multicast address
            let searchRequest = self.searchRequest(host: address, responseTCPPort: nil)

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

    private func searchV2(at address: Socket.Address = .ssdpMulticast) -> Promise<URL> {
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
            let requestConnection = NWConnection(host: .ssdpGroup, port: .ssdp, using: .udp)

            requestConnection.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    let searchRequest = self.searchRequest(
                        host: address,
                        responseTCPPort: listenerPort
                    )
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

    var gatewayDescriptionURL: Promise<URL> {
        return search()
    }
}
