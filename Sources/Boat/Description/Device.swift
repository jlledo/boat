import Foundation

struct Device {
    let type: DeviceType
    let friendlyName: String

    let manufacturer: String
    let manufacturerURL: URL?

    let modelDescription: String?
    let modelName: String
    let modelNumber: String?
    let modelURL: URL?

    let serialNumber: String?

    let udn: String
    let upc: String?

    struct Icon {
        let mimeType: String
        let width: Int
        let height: Int
        let depth: Int
        let url: URLComponents
    }
    let icons: [Icon]
    let services: [Service]
    let subDevices: [Device]

    let presentationURL: URL?

    func findService(ofType type: ServiceType, matchVersion: Bool = false) -> Service? {
        for service in services {
            let isMatch = matchVersion ?
                service.type == type :
                service.type.isCompatible(with: type)
            if isMatch {
                return service
            }
        }

        for device in subDevices {
            if let service = device.findService(ofType: type) {
                return service
            }
        }

        return nil
    }
}

extension Device.Icon: Decodable {
    private enum CodingKeys: String, CodingKey {
        case mimeType = "mimetype"
        case width
        case height
        case depth
        case url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mimeType = try container.decode(String.self, forKey: .mimeType)
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        depth = try container.decode(Int.self, forKey: .depth)
        url = try URLComponents.decode(.url, from: container, decoder: decoder)
    }
}

extension Device: Decodable {
    private enum CodingKeys: String, CodingKey {
        case type = "deviceType"
        case friendlyName
        case manufacturer
        case manufacturerURL
        case modelDescription
        case modelName
        case modelNumber
        case modelURL
        case serialNumber
        case udn = "UDN"
        case upc = "UPC"
        case iconList
        case serviceList
        case deviceList
        case presentationURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        type = try container.decode(DeviceType.self, forKey: .type)
        friendlyName = try container.decode(String.self, forKey: .friendlyName)

        manufacturer = try container.decode(String.self, forKey: .manufacturer)
        manufacturerURL = try URL.decodeIfPresent(
            .manufacturerURL,
            from: container,
            decoder: decoder
        )

        modelDescription = try container.decodeIfPresent(String.self, forKey: .modelDescription)
        modelName = try container.decode(String.self, forKey: .modelName)
        modelNumber = try container.decodeIfPresent(String.self, forKey: .modelNumber)
        modelURL = try URL.decodeIfPresent(.modelURL, from:container, decoder: decoder)

        serialNumber = try container.decodeIfPresent(String.self, forKey: .serialNumber)

        udn = try container.decode(String.self, forKey: .udn)
        upc = try container.decodeIfPresent(String.self, forKey: .upc)

        do {
            let iconList = try container.nestedContainer(
                keyedBy: DynamicKey.self,
                forKey: .iconList
            )
            icons = try iconList.decode([Icon].self, forKey: "icon")
        } catch DecodingError.keyNotFound {
            icons = [Icon]()
        }

        do {
            let serviceList = try container.nestedContainer(
                keyedBy: DynamicKey.self,
                forKey: .serviceList
            )
            services = try serviceList.decode([Service].self, forKey: "service")
        } catch DecodingError.keyNotFound {
            services = [Service]()
        }

        do {
            let deviceList = try container.nestedContainer(
                keyedBy: DynamicKey.self,
                forKey: .deviceList
            )
            subDevices = try deviceList.decode([Device].self, forKey: "device")
        } catch DecodingError.keyNotFound {
            subDevices = [Device]()
        }

        presentationURL = try container.decodeIfPresent(URL.self, forKey: .presentationURL)
    }
}
