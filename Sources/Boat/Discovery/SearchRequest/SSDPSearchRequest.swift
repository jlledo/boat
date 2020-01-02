import Foundation
import Socket

/// SSDP multicast search request.
/// It can also be used for unicast since extra headers will be ignored.
struct SSDPSearchRequest {
    let host: Socket.Address
    static let namespace = "\"ssdp:discover\""
    let timeout: Int = 3
    let target: SSDPSearchTarget
    static let userAgent: ProductIdentifier? = Boat.userAgent
    let responseTCPPort: Int?
    let friendlyName: String
    let uuid: UUIDURI?
}

private extension String {
    mutating func appendHeaderIfExists(_ header: String, value: CustomStringConvertible?) {
        guard let value = value else { return }
        self += "\(header): \(value)\r\n"
    }
}

extension SSDPSearchRequest {
    func ssdpEncoded() -> Data {
        var request = "\(SSDPMessageType.searchRequest.rawValue)\r\n"
        request.appendHeaderIfExists("HOST", value: host)
        request.appendHeaderIfExists("MAN", value: Self.namespace)
        request.appendHeaderIfExists("MX", value: timeout)
        request.appendHeaderIfExists("ST", value: target)
        request.appendHeaderIfExists("USER-AGENT", value: Self.userAgent)
        request.appendHeaderIfExists("TCPPORT.UPNP.ORG", value: responseTCPPort)
        request.appendHeaderIfExists("CPFN.UPNP.ORG", value: friendlyName)
        request.appendHeaderIfExists("CPUUID.UPNP.ORG", value: uuid)
        request.append("\r\n")

        return Data(request.utf8)
    }
}
