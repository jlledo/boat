import Foundation
import Version

struct UPnPDeviceDescriptionV1: UPnPDeviceDescriptionV1Protocol {
    let specVersion: Version
    let urlBase: URL?
    let rootDevice: Device

    init(specVersion: Version, urlBase: URL?, rootDevice: Device) {
        self.specVersion = specVersion
        self.urlBase = urlBase
        self.rootDevice = rootDevice
    }
}

extension UPnPDeviceDescriptionV1: Decodable {
    private enum CodingKeys: String, CodingKey {
        case specVersion
        case urlBase = "URLBase"
        case rootDevice = "device"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        specVersion = try container.decode(Version.self, forKey: .specVersion)
        urlBase = try URL.decodeIfPresent(.urlBase, from: container, decoder: decoder)
        rootDevice = try container.decode(Device.self, forKey: .rootDevice)
    }
}
