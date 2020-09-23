import Foundation

struct GatewayDevice {
    let description: UPnPDeviceDescription

    let descriptionURL: URL

    let service: Service

    init(description: UPnPDeviceDescription, descriptionURL: URL) {
        self.description = description
        self.descriptionURL = descriptionURL
        self.service = description.findService(ofType: .wanIPConnection(1))!
    }
}
