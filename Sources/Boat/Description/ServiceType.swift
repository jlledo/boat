enum ServiceType: Equatable {
    case wanIPConnection(_ version: Int)
    case unsupported(domain: String, type: String, version: Int)

    init(domain: String, type: String, version: Int) {
        if domain == Boat.upnpURNNamespace && type == "WANIPConnection" {
            self = .wanIPConnection(version)
            return
        }
        self = .unsupported(domain: domain, type: type, version: version)
    }

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

extension ServiceType: LosslessStringConvertible {
    init?(_ urn: String) {
        let components = urn.components(separatedBy: ":")
        guard components.count == 5 &&
            components[0] == "urn" &&
            components[2] == "service"
        else {
            return nil
        }

        let domain = components[1]
        let type = components[3]
        guard let version = Int(components[4]) else { return nil }

        self.init(domain: domain, type: type, version: version)
    }
}

extension ServiceType: CustomStringConvertible {
    var description: String {
        var namespace: String
        var serviceType: String
        var serviceVersion: Int

        switch self {
        case .wanIPConnection(let version):
            namespace = Boat.upnpURNNamespace
            serviceType = "WANIPConnection"
            serviceVersion = version
        case .unsupported(let domain, let type, let version):
            namespace = domain
            serviceType = type
            serviceVersion = version
        }

        return "urn:\(namespace):service:\(serviceType):\(serviceVersion)"
    }
}

extension ServiceType: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension ServiceType: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let urn = try container.decode(String.self)

        guard let serviceType = ServiceType(urn) else {
            throw DecodingError.typeMismatch(
                ServiceType.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Value is not a valid ServiceType.")
            )
        }
        self = serviceType
    }
}
