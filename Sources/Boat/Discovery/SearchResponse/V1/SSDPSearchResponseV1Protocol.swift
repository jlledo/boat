import Foundation

protocol SSDPSearchResponseProtocolV1 {
    var cacheValidity: Int { get }
    var date: Date? { get }
    var location: URL { get }
    var server: String { get }
    var searchTarget: SSDPSearchTarget { get }
    var usn: String { get }

    init(from data: Data?) throws
}

extension SSDPSearchResponseProtocolV1 {
    static func parse(
        messageInfo: SSDPMessageInfo
    ) throws -> (
        cacheValidity: Int,
        date: Date?,
        location: URL,
        server: String,
        searchTarget: SSDPSearchTarget,
        usn: String
    ) {
        guard messageInfo.messageType == .searchResponse else {
            throw DiscoveryError.unexpectedMessageType(
                expected: SSDPMessageType.searchResponse.rawValue,
                found: messageInfo.messageType.rawValue
            )
        }
        let headers = messageInfo.headers

        let cacheValidity = try SSDPSearchResponseHelpers.extract(
            header: "CACHE-CONTROL",
            from: headers,
            as: Int.self
        ) { (header, value) in
            guard let cacheValidityString = value.extract(#"max-age=(\d+)"#) else {
                throw DiscoveryError.invalidHeader("\(header): \(value)")
            }
            return cacheValidityString
        }
        let date = try SSDPSearchResponseHelpers.extractIfPresent(
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
        let location = try SSDPSearchResponseHelpers.extract(
            header: "LOCATION",
            from: headers,
            as: URL.self
        )
        let server = try SSDPSearchResponseHelpers.extract(
            header: "SERVER",
            from: headers
        )
        let searchTarget = try SSDPSearchResponseHelpers.extract(
            header: "ST",
            from: headers,
            as: SSDPSearchTarget.self
        )
        let usn = try SSDPSearchResponseHelpers.extract(
            header: "USN",
            from: headers
        )

        return (cacheValidity, date, location, server, searchTarget, usn)
    }
}
