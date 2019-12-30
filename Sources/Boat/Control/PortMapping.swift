import Network
import Promises

public struct PortMapping {
    public let remoteHost: String
    public let externalPort: Int

    public enum TransportProtocol: String,  Codable {
        case tcp = "TCP"
        case udp = "UDP"
    }

    public let transportProtocol: TransportProtocol

    public let internalPort: Int

    // TODO: change internalClient to a cached value
    private let gatewayHost: String
    public var internalClient: Promise<String> {
        return Interface.localAddress(forHost: Host(gatewayHost))
    }

    public let enabled: Bool
    public let description: String
    public let leaseDuration: Int

    public init(
        from externalPort: Int,
        to internalPort: Int,
        transportProtocol: TransportProtocol =  .tcp,
        remoteHost: String = "",
        leaseDuration: Int = 3600,
        description: String,
        gatewayHost: String,
        enable: Bool = true
    ) {
        self.externalPort = externalPort
        self.internalPort = internalPort
        self.transportProtocol = transportProtocol
        self.remoteHost = remoteHost
        self.leaseDuration = leaseDuration
        self.description = description
        self.gatewayHost = gatewayHost
        self.enabled = enable
    }

    func buildActionInvocation(version: Int) -> Promise<UPnPActionInvocation> {
        return internalClient.then { internalClient -> UPnPActionInvocation in
            var arguments = [(String, AnyEncodable)]()
            arguments.append(("NewRemoteHost", AnyEncodable(self.remoteHost)))
            arguments.append(("NewExternalPort", AnyEncodable(self.externalPort)))
            arguments.append(("NewProtocol", AnyEncodable(self.transportProtocol)))
            arguments.append(("NewInternalPort", AnyEncodable(self.internalPort)))
            arguments.append(("NewInternalClient", AnyEncodable(internalClient)))
            arguments.append(("NewEnabled", AnyEncodable(self.enabled ? 1 : 0)))
            arguments.append(("NewPortMappingDescription", AnyEncodable(self.description)))
            arguments.append(("NewLeaseDuration", AnyEncodable(self.leaseDuration)))

            return UPnPActionInvocation(
                action: UPnPActionURN(
                    serviceType: .wanIPConnection(version),
                    name: version == 1 ? "AddPortMapping" : "AddAnyPortMapping"
                ),
                arguments: arguments
            )
        }
    }
}
