enum SSDPSearchTarget {
    case all
    case rootDevice
    case uuid(UUIDURI)
    case device(DeviceType)
    case service(ServiceType)
}

extension SSDPSearchTarget: LosslessStringConvertible {
    var description: String {
        switch self {
        case .all:
            return "ssdp:all"
        case .rootDevice:
            return "upnp:rootdevice"
        case .uuid(let uuid):
            return String(describing: uuid)
        case .device(let type):
            return String(describing: type)
        case .service(let type):
            return String(describing: type)
        }
    }

    init?(_ description: String) {
        switch description {
        case "ssdp:all":
            self = .all
        case "upnp:rootdevice":
            self = .rootDevice
        default:
            if let uuid = UUIDURI(description) {
                self = .uuid(uuid)
            } else if let device = DeviceType(description) {
                self = .device(device)
            } else if let service = ServiceType(description) {
                self = .service(service)
            } else {
                return nil
            }
        }
    }
}
