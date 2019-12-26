import Foundation

enum URIScheme: String {
    case uuid
    case urn
}

protocol URI: LosslessStringConvertible, Codable {
    static var scheme: URIScheme { get }
    var authority: Authority? { get }
    var path: String { get }
    var fragment: String? { get }
    // Might want to add  query component at some point
}

extension URI { // LosslessStringConvertible
    var description: String {
        var authority = ""
        if self.authority != nil {
            authority = "//\(self.authority!)"
        }

        var fragment = ""
        if self.fragment != nil {
            fragment = "#\(self.fragment!)"
        }

        return "\(Self.scheme):\(authority)\(self.path)\(fragment)"
    }
}

extension URI { // Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(describing: self))
    }
}

extension URI { // Decodable
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let description = try container.decode(String.self)

        guard let uri = Self.init(description) else {
            throw DecodingHelpers.typeMismatch(
                value: description,
                type: Self.self,
                decoder: decoder
            )
        }
        self = uri
    }
}
