import Foundation

fileprivate protocol URLType {
    init?(string: String)
}
extension URL: URLType {}
extension URLComponents: URLType {}

fileprivate class URLDecodingHelpers {
    private init() {}

    private static func url<T>(
        from value: String,
        ofType type: T.Type,
        decoder: Decoder
    ) throws -> T where T: URLType {
        guard let url = type.init(string: value) else {
            throw DecodingError.typeMismatch(
                type,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "'\(value)' is not a valid URL."
                )
            )
        }
        return url
    }

    static func decode<T, Key>(
        _ type: T.Type,
        forKey key: Key,
        from container: KeyedDecodingContainer<Key>,
        decoder: Decoder
    ) throws -> T where T: URLType, Key: CodingKey {
        let stringValue = try container.decode(String.self, forKey: key)
        return try Self.url(from: stringValue, ofType: type, decoder: decoder)
    }

    static func decodeIfPresent<T, Key>(
        _ type: T.Type,
        forKey key: Key,
        from container: KeyedDecodingContainer<Key>,
        decoder: Decoder
    ) throws -> T? where T: URLType, Key: CodingKey {
        guard let stringValue = try container.decodeIfPresent(String.self, forKey: key) else {
            return nil
        }
        return try Self.url(from: stringValue, ofType: type, decoder: decoder)
    }
}

extension URL {
    static func decode<Key>(
        _ key: Key,
        from container: KeyedDecodingContainer<Key>,
        decoder: Decoder
    ) throws -> URL where Key: CodingKey {
        return try URLDecodingHelpers.decode(
            self.self,
            forKey: key,
            from: container,
            decoder: decoder
        )
    }

    static func decodeIfPresent<Key>(
        _ key: Key,
        from container: KeyedDecodingContainer<Key>,
        decoder: Decoder
    ) throws -> URL? where Key: CodingKey {
        return try URLDecodingHelpers.decodeIfPresent(
            self.self,
            forKey: key,
            from: container,
            decoder: decoder
        )
    }
}

extension URLComponents {
    static func decode<Key>(
        _ key: Key,
        from container: KeyedDecodingContainer<Key>,
        decoder: Decoder
    ) throws -> URLComponents where Key: CodingKey {
        return try URLDecodingHelpers.decode(
            self.self,
            forKey: key,
            from: container,
            decoder: decoder
        )
    }

    static func decodeIfPresent<Key>(
        _ key: Key,
        from container: KeyedDecodingContainer<Key>,
        decoder: Decoder
    ) throws -> URLComponents? where Key: CodingKey {
        return try URLDecodingHelpers.decodeIfPresent(
            self.self,
            forKey: key,
            from: container,
            decoder: decoder
        )
    }
}
