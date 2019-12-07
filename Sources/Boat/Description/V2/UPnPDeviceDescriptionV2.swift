import Foundation
import XMLCoder

struct UPnPDeviceDescriptionV2: UPnPDeviceDescriptionV2Protocol {
    let configID: Int
    let specVersion: Version
    let urlBase: URL?
    let rootDevice: Device
}

extension UPnPDeviceDescriptionV2: Decodable {
    private enum CodingKeys: String, CodingKey {
        case configID = "configId"
        case specVersion
        case urlBase = "URLBase"
        case rootDevice = "device"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        configID = try container.decode(Int.self, forKey: .configID)
        specVersion = try container.decode(Version.self, forKey: .specVersion)
        urlBase = try URL.decodeIfPresent(.urlBase, from: container, decoder: decoder)
        rootDevice = try container.decode(Device.self, forKey: .rootDevice)
    }
}

extension UPnPDeviceDescriptionV2: DynamicNodeDecoding {
    static func nodeDecoding(for key: CodingKey) -> XMLDecoder.NodeDecoding {
        switch key {
        case CodingKeys.configID: return .attribute
        default: return .element
        }
    }
}
