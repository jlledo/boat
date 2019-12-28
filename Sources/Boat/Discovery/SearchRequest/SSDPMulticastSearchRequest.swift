import Foundation

struct SSDPMulticastSearchRequest {
    static let requestLine: SSDPMessageType = .searchRequest

    static let host: String = "239.255.255.250:1900"
    static let namespace = "\"ssdp:discover\""
    let timeout: Int = 3
    let target: SSDPSearchTarget
    static let userAgent: String? = Boat.userAgent
    let responseTCPPort: Int?
    let friendlyName: String
    let uuid: String?
}

private extension String {
    mutating func appendHeaderIfExists(_ header: String, value: CustomStringConvertible?) {
        guard let value = value else { return }
        self += "\(header): \(value)\r\n"
    }
}

extension SSDPMulticastSearchRequest {
    func ssdpEncoded() -> Data {
        var request = "\(Self.requestLine.rawValue)\r\n"
        request.appendHeaderIfExists("HOST", value: Self.host)
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
