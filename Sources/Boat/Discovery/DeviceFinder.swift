import Foundation
import Network
import Promises
import Socket

struct DeviceFinder {
    static let ssdpTimeoutRange: ClosedRange = 1...5

    static let unicastSearchTimeout: Int = 1

    static let timeoutFudgeFactor: Double = 0.2

    let address: Socket.Address

    let timeout: Int

    let target: SSDPSearchTarget

    let friendlyName: String

    let uuid: UUIDURI?

    let socketProvider: SocketProviderProtocol.Type

    private var searchRequest: SSDPSearchRequest {
        SSDPSearchRequest(
            host: address,
            timeout: timeout,
            target: target,
            responseTCPPort: nil,
            friendlyName: friendlyName,
            uuid: uuid
        )
    }

    /// Init DeviceFinder for multicast search
    init(
        timeout: Int = 3,
        target: SSDPSearchTarget,
        friendlyName: String,
        uuid: UUIDURI?,
        socketProvider: SocketProviderProtocol.Type = SocketProvider.self
    ) {
        #if DEBUG
        let timeout = Self.ssdpTimeoutRange.lowerBound
        #endif

        self.address = .ssdpMulticast
        self.timeout = timeout.clamped(to: Self.ssdpTimeoutRange)
        self.target = target
        self.friendlyName = friendlyName
        self.uuid = uuid
        self.socketProvider = socketProvider
    }

    /// Init DeviceFinder for unicast search
    init(
        address: Socket.Address,
        target: SSDPSearchTarget,
        friendlyName: String,
        uuid: UUIDURI?,
        socketProvider: SocketProviderProtocol.Type = SocketProvider.self
    ) {
        self.address = address
        self.timeout = Self.unicastSearchTimeout
        self.target = target
        self.friendlyName = friendlyName
        self.uuid = uuid
        self.socketProvider = socketProvider
    }

    static func gatewayFinder(version: Int, friendlyName: String) -> DeviceFinder {
        DeviceFinder(
            target: .service(.wanIPConnection(version)),
            friendlyName: friendlyName,
            uuid: nil
        )
    }

    func search(attempts: Int = 3) -> Promise<[SSDPSearchResponse]> {
        // Dispatch on global queue to avoid waiting on Main thread in readDatagram(into:)
        return Promise(on: .global()) { fulfill, reject in
            // Create socket
            let socket = try self.socketProvider.create(family: .inet, type: .datagram, proto: .udp)
            defer {
                socket.close()
            }

            var decodedResponses: [SSDPSearchResponse] = []
            var retryCount: Int = 0
            while retryCount < attempts && decodedResponses.isEmpty {
                // Send search query to requested address
                try socket.write(from: self.searchRequest.ssdpEncoded(), to: self.address)

                // Read responses until timeout
                // Timeout is fudged to account for network delay and processing time
                let timeoutDate = Date() + (Double(self.timeout) * (1.0 + Self.timeoutFudgeFactor))
                var responses: [Data] = []
                while true {
                    let timeLeftMilliseconds = timeoutDate.timeIntervalSince(Date()) * 1000
                    try socket.setReadTimeout(value: UInt(max(timeLeftMilliseconds, 0)))

                    var data = Data()
                    let (bytes, _) = try socket.readDatagram(into: &data)

                    // Check socket read has not timed out
                    guard !(bytes == 0 && errno == EAGAIN) else {
                        break
                    }
                    responses.append(data)
                }

                // Decode responses
                decodedResponses = responses.compactMap { try? SSDPSearchResponse(from: $0) }

                retryCount += 1
            }
            fulfill(decodedResponses)
        }
    }

    private static func getLatestService(
        from responses: [SSDPSearchResponse]
    ) throws -> SSDPSearchResponse {
        var maxVersion: Int = 0
        var maxVersionResponse: SSDPSearchResponse? = nil
        for response in responses {
            guard case .service(.wanIPConnection(let version)) = response.searchTarget else {
                continue
            }
            guard version != maxVersion else {
                throw DiscoveryError.tooManyGateways
            }
            if version > maxVersion {
                maxVersion = version
                maxVersionResponse = response
            }
        }

        guard let response = maxVersionResponse else {
            throw DiscoveryError.gatewayNotFound
        }
        return response
    }

    static func searchGateway(friendlyName: String) -> Promise<SSDPSearchResponse> {
        // Search for all supported WANIPConnection versions
        let searchV1Promise = gatewayFinder(version: 1, friendlyName: friendlyName).search()
        let searchV2Promise = gatewayFinder(version: 2, friendlyName: friendlyName).search()
        return all([searchV1Promise, searchV2Promise]).then {
            try getLatestService(from: $0.reduce([], +))
        }
    }
}
