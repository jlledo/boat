class DecodingHelpers {
    static func typeMismatch(value: String, type: Any.Type, decoder: Decoder) -> DecodingError {
        return DecodingError.typeMismatch(
            type,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "'\(value)' is not a valid \(type)."
            )
        )
    }
}
