import Foundation

struct SSDPSearchResponseV2: SSDPSearchResponseProtocolV2 {
    let cacheValidity: Int
    let date: Date?
    let location: URL
    let server: ProductIdentifier?
    let searchTarget: SSDPSearchTarget
    let usn: String
    let bootId: Int
    let configId: Int?
    let searchPort: Int?
    let secureLocation: URL?
}

extension SSDPSearchResponseV2 {
    init(from data: Data?) throws {
        let messageInfo = try SSDPParser.parse(data)
        (cacheValidity, date, location, server, searchTarget, usn)
            = try Self.parse(messageInfo: messageInfo)

        let headers = messageInfo.headers

        self.bootId = try SSDPSearchResponseHelpers.extract(
            header: "BOOTID.UPNP.ORG",
            from: headers,
            as: Int.self
        )
        self.configId = try SSDPSearchResponseHelpers.extractIfPresent(
            header: "CONFIGID.UPNP.ORG",
            from: headers,
            as: Int.self
        )
        self.searchPort = try SSDPSearchResponseHelpers.extractIfPresent(
            header: "SEARCHPORT.UPNP.ORG",
            from: headers,
            as: Int.self
        )
        self.secureLocation = try SSDPSearchResponseHelpers.extractIfPresent(
            header: "SECURELOCATION.UPNP.ORG",
            from: headers,
            as: URL.self
        )
    }
}
