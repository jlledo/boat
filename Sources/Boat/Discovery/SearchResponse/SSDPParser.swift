import Foundation

enum SSDPParser {
    static func parse(_ data: Data) throws -> SSDPMessageInfo
    {
        let lines = String(decoding: data, as: UTF8.self).split(separator: "\r\n")
        guard !lines.isEmpty else {
            throw SSDPParserError.invalidSSDPMessageType("Message is empty.")
        }

        let startLine = String(lines[0])
        guard let messageType = SSDPMessageType(rawValue: startLine) else {
            throw SSDPParserError.invalidSSDPMessageType(startLine)
        }

        var headers: [String: String] = [:]
        for line in lines[1..<lines.count] {
            let pair = line.split(separator: ":", maxSplits: 1)

            let header = String(pair[0])
            guard headers[header] == nil else {
                throw SSDPParserError.duplicateHeader(String(line))
            }

            if pair.count == 2 {
                headers[header] = pair[1].trimmingCharacters(in: .whitespaces)
            } else { // pair.count == 1 due to splitting at most once
                headers[header] = ""
            }
        }

        return SSDPMessageInfo(messageType: messageType, headers: headers)
    }
}

enum SSDPParserError: Error {
    case missingData
    case corruptData
    case invalidSSDPMessageType(String)
    case invalidSSDPHeader(String)
    case duplicateHeader(String)
}
