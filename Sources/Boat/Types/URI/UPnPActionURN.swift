struct UPnPActionURN {
    let object: ServiceType
    let action: String
}

extension UPnPActionURN: URI {
    static let scheme: URIScheme = .urn

    var authority: Authority? { nil }

    var path: String { object.path }

    var fragment: String? { action }
}

extension UPnPActionURN { // LosslessStringConvertible
    init?(_ description: String) {
        let components = description.split(separator: "#")
        guard components.count == 2 else { return nil }

        guard let service = ServiceType(String(components[0])) else { return nil }
        object = service

        action = String(components[1])
    }
}
