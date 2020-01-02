import Foundation
import Version
import XMLCoder

struct UPnPDeviceDescription {
    let configId: Int?
    let specVersion: Version
    let urlBase: URL?
    let rootDevice: Device

    func findService(ofType type: ServiceType, matchVersion: Bool = false) -> Service? {
        return rootDevice.findService(ofType: type, matchVersion: matchVersion)
    }
}

extension UPnPDeviceDescription: Decodable {
    private enum CodingKeys: String, CodingKey {
        case configId
        case specVersion
        case urlBase = "URLBase"
        case rootDevice = "device"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        configId = try container.decodeIfPresent(Int.self, forKey: .configId)
        specVersion = try container.decode(Version.self, forKey: .specVersion)
        urlBase = try URL.decodeIfPresent(.urlBase, from: container, decoder: decoder)
        rootDevice = try container.decode(Device.self, forKey: .rootDevice)
    }
}

extension UPnPDeviceDescription: DynamicNodeDecoding {
    static func nodeDecoding(for key: CodingKey) -> XMLDecoder.NodeDecoding {
        switch key {
        case CodingKeys.configId: return .attribute
        default: return .element
        }
    }
}
