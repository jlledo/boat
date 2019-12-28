struct UPnPActionURN {
    let objectType: ServiceType
    let name: String
}

extension UPnPActionURN: URI {
    static let scheme: URIScheme = .urn

    var authority: Authority? { nil }

    var path: String { objectType.path }

    var fragment: String? { name }
}

extension UPnPActionURN { // LosslessStringConvertible
    init?(_ description: String) {
        let components = description.split(separator: "#")
        guard components.count == 2 else { return nil }

        guard let service = ServiceType(String(components[0])) else { return nil }
        objectType = service

        name = String(components[1])
    }
}
