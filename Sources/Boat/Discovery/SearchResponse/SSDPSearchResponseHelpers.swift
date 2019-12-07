class SSDPSearchResponseHelpers {
    private init() {}

    static func extract(
        header: String,
        from headerDict: [String: String]
    ) throws -> String {
        return try extract(header: header, from: headerDict, as: String.self)
    }

    static func extract<T>(
        header: String,
        from headerDict: [String: String],
        using converter: (_ header: String, _ value: String) throws -> T
    ) throws -> T {
        let value = try extract(header: header, from: headerDict)
        return try converter(header, value)
    }

    static func extract<T>(
        header: String,
        from headerDict: [String: String],
        as type: T.Type,
        using extractor: ((_ header: String, _ value: String) throws -> String)? = nil
    ) throws -> T where T: LosslessStringConvertible {
        guard let headerValue = headerDict[header] else {
            throw DiscoveryError.missingRequiredHeader(header)
        }

        let extractedValue = try extractor?(header, headerValue) ?? headerValue

        guard let castedValue = type.init(extractedValue) else {
            throw DiscoveryError.incompatibleHeaderType(
                type: String(describing: type),
                header: "\(header): \(headerValue)"
            )
        }
        return castedValue
    }

    static func extractIfPresent<T>(
        header: String,
        from headerDict: [String: String],
        using converter: (_ header: String, _ value: String) throws -> T
    ) throws -> T? {
        guard headerDict[header] != nil else { return nil }
        return try extract(header: header, from: headerDict, using: converter)
    }

    static func extractIfPresent<T>(
        header: String,
        from headerDict: [String: String],
        as type: T.Type,
        using extractor: ((_ header: String, _ value: String) throws -> String)? = nil
    ) throws -> T? where T: LosslessStringConvertible {
        guard headerDict[header] != nil else { return nil }
        return try extract(header: header, from: headerDict, as: type, using: extractor)
    }
}
