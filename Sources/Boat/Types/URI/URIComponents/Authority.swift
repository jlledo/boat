struct Authority {
    // Might want to add userinfo at some point
    let host: String
    let port: Int?
}

extension Authority: LosslessStringConvertible {
    var description: String {
        if let port = port {
            return "\(host):\(port)"
        }
        return host
    }

    init?(_ description: String) {
        let components = description.split(separator: ":")
        let host = String(components[0])
        var port: Int?
        if components.count == 2 {
            guard let unwrappedPort = Int(components[1]) else { return nil }
            port = unwrappedPort
        }
        self.init(host: host, port: port)
    }
}

extension Authority: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(describing: self))
    }
}

extension Authority: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)

        guard let authority = Self.init(description) else {
            throw DecodingHelpers.typeMismatch(
                value: description,
                type: Self.self,
                decoder: decoder
            )
        }
        self = authority
    }
}
