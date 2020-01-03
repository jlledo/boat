import Network
import Promises

public struct PortMapping {
    public enum TransportProtocol: String,  Codable {
        case tcp = "TCP"
        case udp = "UDP"
    }

    public let remoteHost: String = ""
    public let externalPort: Int
    public let transportProtocol: TransportProtocol = .tcp
    public let internalPort: Int
    public let internalClient: String
    public let enabled: Bool = true
    public let description: String
    #if DEBUG
    public let leaseDuration: Int = 60
    #else
    public let leaseDuration: Int = 3600
    #endif

    func asControlMessage(forVersion version: Int) -> UPnPControlMessage {
        let arguments: [(String, AnyEncodable)] = [
            ("NewRemoteHost",               AnyEncodable(remoteHost)),
            ("NewExternalPort",             AnyEncodable(externalPort)),
            ("NewProtocol",                 AnyEncodable(transportProtocol)),
            ("NewInternalPort",             AnyEncodable(internalPort)),
            ("NewInternalClient",           AnyEncodable(internalClient)),
            ("NewEnabled",                  AnyEncodable(enabled ? 1 : 0)),
            ("NewPortMappingDescription",   AnyEncodable(description)),
            ("NewLeaseDuration",            AnyEncodable(leaseDuration)),
        ]

        return UPnPControlMessage(
            action: UPnPActionURN(
                serviceType: .wanIPConnection(version),
                name: version == 1 ? "AddPortMapping" : "AddAnyPortMapping"
            ),
            arguments: arguments
        )
    }
}
