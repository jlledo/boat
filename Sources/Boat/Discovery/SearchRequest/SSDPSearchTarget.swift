enum SSDPSearchTarget {
    case all
    case rootDevice
    case uuid(String)
    case device(DeviceType)
    case service(ServiceType)
}

extension SSDPSearchTarget: LosslessStringConvertible {
    init?(_ targetString: String) {
        switch targetString {
        case "ssdp:all": self = .all
        case "upnp:rootdevice": self = .rootDevice
        default:
            let components = targetString.components(separatedBy: ":")
            guard !components.isEmpty else {
                return nil
            }
            if components[0] == "uuid" && components.count == 2 {
                self = .uuid(components[1])
            } else if let device = DeviceType(targetString) {
                self = .device(device)
            } else if let service = ServiceType(targetString) {
                self = .service(service)
            } else {
                return nil
            }
        }
    }
}

extension SSDPSearchTarget: CustomStringConvertible {
    var description: String {
        switch self {
        case .all:
            return "ssdp:all"
        case .rootDevice:
            return "upnp:rootdevice"
        case .uuid(let uuid):
            return uuid
        case .device(let type):
            return String(describing: type)
        case .service(let type):
            return String(describing: type)
        }
    }
}
