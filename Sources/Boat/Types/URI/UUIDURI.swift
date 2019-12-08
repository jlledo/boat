import Foundation

struct UUIDURI: URI {
    let uuid: String
}

extension UUIDURI { // URI
    static let scheme: URIScheme = .uuid

    var authority: Authority? { nil }

    var path: String { "uuid:\(self.uuid)" }
}

extension UUIDURI { // LosslessStringConvertible
    init?(_ description: String) {
        let components = description.split(separator: ":")
        guard components.count == 2 &&
            components[0] == "uuid"
        else {
            return nil
        }

        self.init(uuid: String(components[1]))
    }
}
