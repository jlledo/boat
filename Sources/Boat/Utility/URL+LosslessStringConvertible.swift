import Foundation

extension URL: LosslessStringConvertible {
    public init?(_ description: String) {
        self.init(string: description)
    }
}
