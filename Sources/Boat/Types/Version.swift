public struct Version: Codable {
    public let major: Int
    public let minor: Int
    public let patch: Int?

    public init(major: Int, minor: Int, patch: Int? = nil) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
}
