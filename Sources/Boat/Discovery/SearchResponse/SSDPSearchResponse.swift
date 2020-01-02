import Foundation

struct SSDPSearchResponse {
    let cacheValidity: Int
    let date: Date?
    let location: URL
    // Required in UDA v1, but optional because we need to tolerate failure
    let server: ProductIdentifier?
    let searchTarget: SSDPSearchTarget
    let usn: String
    // UDA v2.0
    // Required in UDA v2.0, but optional for v1 compatiblity
    let bootId: Int?
    let configId: Int?
    let searchPort: Int?
    let secureLocation: URL?
}

extension SSDPSearchResponse {
    init(from data: Data) throws {
        let messageInfo = try SSDPParser.parse(data)
        guard messageInfo.messageType == .searchResponse else {
            throw DiscoveryError.unexpectedMessageType(
                expected: SSDPMessageType.searchResponse.rawValue,
                found: messageInfo.messageType.rawValue
            )
        }
        let headers = messageInfo.headers

        self.cacheValidity = try SSDPSearchResponseHelpers.extract(
            header: "CACHE-CONTROL",
            from: headers,
            as: Int.self
        ) { (header, value) in
            guard let cacheValidityString = value.extract(#"max-age=(\d+)"#) else {
                throw DiscoveryError.invalidHeader("\(header): \(value)")
            }
            return cacheValidityString
        }
        self.date = try SSDPSearchResponseHelpers.extractIfPresent(
            header: "DATE",
            from: headers
        ) { (header, value) -> Date in
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

            guard let date = dateFormatter.date(from: value) else {
                throw DiscoveryError.incompatibleHeaderType(
                    type: "Date",
                    header: "\(header): \(value)"
                )
            }
            return date
        }
        self.location = try SSDPSearchResponseHelpers.extract(
            header: "LOCATION",
            from: headers,
            as: URL.self
        )
        self.server = try? SSDPSearchResponseHelpers.extract(
            header: "SERVER",
            from: headers,
            as: ProductIdentifier.self
        )
        self.searchTarget = try SSDPSearchResponseHelpers.extract(
            header: "ST",
            from: headers,
            as: SSDPSearchTarget.self
        )
        self.usn = try SSDPSearchResponseHelpers.extract(
            header: "USN",
            from: headers
        )
        self.bootId = try? SSDPSearchResponseHelpers.extract(
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
