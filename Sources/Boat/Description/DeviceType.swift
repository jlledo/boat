enum DeviceType: Equatable {
    case internetGatewayDevice(_ version: Int)
    case unsupported(domain: String, type: String, version: Int)

    init(domain: String, type: String, version: Int) {
        if domain == Boat.upnpURNNamespace && type == "InternetGatewayDevice" {
            self = .internetGatewayDevice(version)
            return
        }
        self = .unsupported(domain: domain, type: type, version: version)
    }
}

extension DeviceType: LosslessStringConvertible {
    init?(_ urn: String) {
        let components = urn.components(separatedBy: ":")
        guard components.count == 5 &&
              components[0] == "urn" &&
              components[2] == "device"
        else {
            return nil
        }

        let domain = components[1]
        let type = components[3]
        guard let version = Int(components[4]) else { return nil }

        self.init(domain: domain, type: type, version: version)
    }
}

extension DeviceType: CustomStringConvertible {
    var description: String {
        var namespace: String
        var deviceType: String
        var deviceVersion: Int

        switch self {
        case .internetGatewayDevice(let version):
            namespace = Boat.upnpURNNamespace
            deviceType = "InternetGatewayDevice"
            deviceVersion = version
        case .unsupported(let domain, let type, let version):
            namespace = domain
            deviceType = type
            deviceVersion = version
        }

        return "urn:\(namespace):device:\(deviceType):\(deviceVersion)"
    }
}

extension DeviceType: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension DeviceType: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let urn = try container.decode(String.self)

        guard let deviceType = DeviceType(urn) else {
            throw DecodingError.typeMismatch(
                DeviceType.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Value is not a valid DeviceType.")
            )
        }
        self = deviceType
    }
}
