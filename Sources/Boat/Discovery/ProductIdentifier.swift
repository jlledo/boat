import Foundation
import Version

struct ProductIdentifier {
    struct Token {
        let name: String
        let version: Version
    }

    let os: Token
    let upnp: Token
    let product: Token
}

extension ProductIdentifier: LosslessStringConvertible {
    init?(_ description: String) {
        let tokens = description.components(separatedBy: .whitespaces)
        guard tokens.count == 3,
            let os = Token(tokens[0]),
            let upnp = Token(tokens[1]),
            let product = Token(tokens[2])
        else {
            return nil
        }
        self.os = os
        self.upnp = upnp
        self.product = product
    }

    var description: String { "\(os) \(upnp) \(product)"}
}

extension ProductIdentifier.Token: LosslessStringConvertible {
    init?(_ description: String) {
        let regex = try! NSRegularExpression(pattern: #"(\S+)\/(\S+)"#)

        let searchRange = NSRange(description.startIndex..., in: description)
        guard let match = regex.firstMatch(in: description, range: searchRange) else { return nil }

        guard let nameRange = Range(match.range(at: 1), in: description) else { return nil }

        guard let versionRange = Range(match.range(at: 2), in: description) else { return nil }
        guard let version = Version(String(description[versionRange])) else { return nil }

        self.name = String(description[nameRange])
        self.version = version
    }

    var description: String { "\(name)/\(version)" }
}
