enum ServiceType: Equatable {
    case wanIPConnection(_ version: Int)
    case unsupported(namespace: String, name: String, version: Int)

    func isCompatible(with otherType: ServiceType) -> Bool {
        switch (self, otherType) {
        case let (.wanIPConnection(a), .wanIPConnection(b)):
            return a >= b

        case let (.unsupported(domainA, typeA, versionA), .unsupported(domainB, typeB, versionB)):
            guard (domainA == domainB) && (typeA == typeB) else {
                return false
            }
            return versionA >= versionB

        default:
            return false
        }
    }
}

extension ServiceType: UPnPObjectURN {
    var namespace: String {
        switch self {
        case .wanIPConnection:
            return Boat.upnpURNNamespace
        case .unsupported(let namespace, _, _):
            return namespace
        }
    }
    
    static let type: URNType = .service
    
    var name: String {
        switch self {
        case .wanIPConnection:
            return "WANIPConnection"
        case .unsupported(_, let name, _):
            return name
        }
    }
    
    var version: Int {
        switch self {
        case .wanIPConnection(let version),
             .unsupported(_, _, let version):
            return version
        }
    }

    init(namespace: String, name: String, version: Int) {
        if namespace == Boat.upnpURNNamespace && name == "WANIPConnection" {
            self = .wanIPConnection(version)
            return
        }
        self = .unsupported(namespace: namespace, name: name, version: version)
    }
}
