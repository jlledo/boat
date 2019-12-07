struct DynamicKey: CodingKey {
    let stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    let intValue: Int?
    init?(intValue: Int) { return nil }

    init(_ value: String) {
        stringValue = value
        intValue = nil
    }

    static let `super` = DynamicKey("super")
}

extension DynamicKey: ExpressibleByStringLiteral {
    init(stringLiteral value: StaticString) {
        self = DynamicKey("\(value)")
    }
}
