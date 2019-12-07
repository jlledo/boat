import Foundation

protocol SSDPSearchResponseProtocolV2: SSDPSearchResponseProtocolV1 {
    var bootID: Int { get }
    var configID: Int? { get }
    var searchPort: Int? { get }
    var secureLocation: URL? { get }
}
