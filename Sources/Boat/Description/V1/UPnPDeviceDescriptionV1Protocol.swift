import Foundation

protocol UPnPDeviceDescriptionV1Protocol {
    var specVersion: Version { get }
    var urlBase: URL? { get }
    var rootDevice: Device { get }

    func findService(ofType type: ServiceType, matchVersion: Bool) -> Service?
}

extension UPnPDeviceDescriptionV1Protocol {
    func findService(ofType type: ServiceType, matchVersion: Bool = false) -> Service? {
        return rootDevice.findService(ofType: type, matchVersion: matchVersion)
    }
}
