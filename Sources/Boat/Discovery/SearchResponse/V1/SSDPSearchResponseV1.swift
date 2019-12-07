import Foundation

struct SSDPSearchResponseV1: SSDPSearchResponseProtocolV1 {
    let cacheValidity: Int
    let date: Date?
    let location: URL
    let server: String
    let searchTarget: SSDPSearchTarget
    let usn: String
}

extension SSDPSearchResponseV1 {
    init(from data: Data?) throws {
        let messageInfo = try SSDPParser.parse(data)
        (cacheValidity, date, location, server, searchTarget, usn)
            = try Self.parse(messageInfo: messageInfo)
    }
}
