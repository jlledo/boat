import Foundation

enum URNType: String {
    case device
    case service
}

protocol URN: URI {
    var namespace: String { get }
    static var type: URNType { get }
    var name: String { get }
    var version: Int { get }

    init(namespace: String, name: String, version: Int)
}

extension URN { // URI
    static var scheme: URIScheme { .urn }

    var authority: Authority? { nil }

    var path: String {
        return [
            namespace,
            Self.type.rawValue,
            name,
            String(version)
        ].joined(separator: ":")
    }
}

extension URN { // LosslessStringConvertible
    init?(_ description: String) {
        let components = description.split(separator: ":")
        guard components.count == 5 &&
            components[0] == "urn" &&
            components[2] == Self.type.rawValue
        else {
            return nil
        }

        let namespace = components[1]
        let name = components[3]
        guard let version = Int(components[4]) else { return nil }

        self.init(namespace: String(namespace), name: String(name), version: version)
    }
}
