import Foundation
import Network
import Promises
import Socket

class UPnPDiscovery {
    private init() {}

    static func searchForV1(target: SSDPSearchTarget, friendlyName: String) -> Promise<URL> {
        // Dispatch on global queue to avoid waiting on Main thread in readDatagram(into:)
        return Promise(on: .global()) { fulfill, reject in
            // Create socket
            let socket = try Socket.create(family: .inet, type: .datagram, proto: .udp)
            defer {
                socket.close()
            }

            // Send query to SSDP multicast address
            let searchRequestData = SSDPMulticastSearchRequest(
                timeout: 1,
                target: target,
                responseTCPPort: nil,
                friendlyName: friendlyName,
                uuid: nil
            ).ssdpEncoded()

            let destinationSocketAddress = Socket.createAddress(for: "239.255.255.250", on: 1900)!
            try socket.write(from: searchRequestData, to: destinationSocketAddress)

            // Read response
            var searchResponseData = Data()
            _ = try socket.readDatagram(into: &searchResponseData)

            // Decode response
            let response = try SSDPSearchResponseV1(from: searchResponseData)

            fulfill(response.location)
        }.timeout(1.5)
    }

    static func searchForV2(target: SSDPSearchTarget, friendlyName: String) -> Promise<URL> {
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
                    let searchRequest = SSDPMulticastSearchRequest(
                        timeout: 1,
                        target: target,
                        responseTCPPort: listenerPort,
                        friendlyName: friendlyName,
                        uuid: nil
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

    static func searchFor(target: SSDPSearchTarget, friendlyName: String) -> Promise<URL> {
        let descriptionURLV2 = searchForV2(target: target, friendlyName: friendlyName)
        let descriptionURLV1 = searchForV1(target: target, friendlyName: friendlyName)

        return race([descriptionURLV2, descriptionURLV1])
    }

    static var gatewayDescriptionURL: Promise<URL> {
        return searchFor(target: .all, friendlyName: "Boat")
    }
}
