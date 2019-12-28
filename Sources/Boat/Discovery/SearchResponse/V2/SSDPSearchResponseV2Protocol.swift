import Foundation

protocol SSDPSearchResponseProtocolV2: SSDPSearchResponseProtocolV1 {
    var bootId: Int { get }
    var configId: Int? { get }
    var searchPort: Int? { get }
    var secureLocation: URL? { get }
}
