import Foundation

struct Service {
    var type: ServiceType
    var id: String
    var scpdURL: URLComponents
    var controlURL: URLComponents
    var eventSubURL: URLComponents
}

extension Service: Decodable {
    enum CodingKeys: String, CodingKey {
        case type = "serviceType"
        case id = "serviceId"
        case scpdURL = "SCPDURL"
        case controlURL
        case eventSubURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(ServiceType.self, forKey: .type)
        id = try container.decode(String.self, forKey: .id)
        scpdURL = try URLComponents.decode(.scpdURL, from: container, decoder: decoder)
        controlURL = try URLComponents.decode(.controlURL, from: container, decoder: decoder)
        eventSubURL = try URLComponents.decode(.eventSubURL, from: container, decoder: decoder)
    }
}
