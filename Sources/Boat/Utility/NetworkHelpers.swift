import Network

typealias Host = NWEndpoint.Host
typealias Port = NWEndpoint.Port

// MARK: - SSDP Constants
extension IPv4Address {
    /// The multicast group for all SSDP devices (239.255.255.250).
    static let ssdpGroup: IPv4Address = IPv4Address("239.255.255.250")!
}

extension Host {
    /// The multicast group for all SSDP devices (239.255.255.250).
    static let ssdpGroup = Host.ipv4(.ssdpGroup)
}

extension Port {
    /// The Simple Service Discovery Protocol port (port 1900).
    static let ssdp: Port = 1900
}
