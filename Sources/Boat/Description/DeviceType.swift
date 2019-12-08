enum DeviceType: Equatable {
    case internetGatewayDevice(_ version: Int)
    case unsupported(namespace: String, name: String, version: Int)
}

extension DeviceType: URN {
    var namespace: String {
        switch self {
        case .internetGatewayDevice:
            return Boat.upnpURNNamespace
        case .unsupported(let namespace, _, _):
            return namespace
        }
    }

    static let type: URNType = .device

    var name: String {
        switch self {
        case .internetGatewayDevice:
            return "InternetGatewayDevice"
        case .unsupported(_, let name, _):
            return name
        }
    }

    var version: Int {
        switch self {
        case .internetGatewayDevice(let version),
             .unsupported(_, _, let version):
            return version
        }
    }

    init(namespace: String, name: String, version: Int) {
        if namespace == Boat.upnpURNNamespace && name == "InternetGatewayDevice" {
            self = .internetGatewayDevice(version)
            return
        }
        self = .unsupported(namespace: namespace, name: name, version: version)
    }
}
