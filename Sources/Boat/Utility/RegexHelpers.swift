import Foundation

extension String {
    func extract(_ pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let searchRange = NSRange(self.startIndex..., in: self)
        guard let match = regex.firstMatch(in: self,range: searchRange) else { return nil }

        guard let matchRange = Range(match.range(at: 1), in: self) else { return nil }

        return String(self[matchRange])
    }
}
