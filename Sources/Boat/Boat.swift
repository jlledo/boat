import Foundation
import Network
import Promises
import XMLCoder

public struct Boat {
    public static let packageName = "Boat"
    public static let packageVersion = Version(major: 0, minor: 1)

    static let osName = "macOS"

    static var userAgent: String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return """
            \(Boat.osName)/\(osVersion.majorVersion).\(osVersion.minorVersion) \
            UPnP/2.0 \
            \(Boat.packageName)/\(packageVersion.major).\(packageVersion.minor)
            """
    }

    static let upnpURNNamespace = "schemas-upnp-org"

//    var timers: [PortMappingRequest: Timer] = [:]

    static func endpoint(
        forService serviceType: ServiceType,
        matchVersion: Bool = false
    ) -> Promise<URL> {
        let descriptionURLPromise = DeviceFinder(
            target: .service(serviceType),
            friendlyName: "Boat"
        ).search()

        let baseURLPromise = descriptionURLPromise.then { url -> URLComponents in
            var components = URLComponents()
            components.scheme = url.scheme
            components.host = url.host
            components.port = url.port
            return components
        }

        let controlURLPromise = descriptionURLPromise.then {
            URLSession.shared.fetchData(from: $0)
        }.timeout(2) // 1 second is sometimes too fast to get a response
        .then { arg0 -> UPnPDeviceDescriptionV1Protocol in
            let (data, _) = arg0
            var description: UPnPDeviceDescriptionV1Protocol
            do {
                description = try XMLDecoder().decode(
                    UPnPDeviceDescriptionV2.self,
                    from: data
                )
            } catch {
                description = try XMLDecoder().decode(
                    UPnPDeviceDescriptionV1.self,
                    from: data
                )
            }
            return description
        }.then { description -> URLComponents in
            guard let service = description.findService(ofType: serviceType) else {
                throw BoatError.serviceNotFound
            }
            return service.controlURL
        }

        return all(baseURLPromise, controlURLPromise).then { (baseURL, controlURL) -> URL in
            var controlURLComponents = baseURL
            controlURLComponents.path = controlURL.path
            guard let url = controlURLComponents.url else {
                throw BoatError.invalidURL
            }
            return url
        }
    }

    static func requestMapping(
        forPort port: Int,
        endpoint: URL,
        programName: String,
        version: Int
    ) -> Promise<Int> {
        guard let gatewayHost = endpoint.host else {
            return Promise(BoatError.invalidURL)
        }

        #if DEBUG
            let portMapping = PortMapping(
                from: port,
                to: port,
                leaseDuration: 60,
                description: programName,
                gatewayHost: gatewayHost
            )
        #else
            let portMapping = PortMapping(
                from: port,
                to: port,
                description: programName,
                gatewayHost: gatewayHost
            )
        #endif

        return portMapping.buildActionInvocation(version: version).then {
            URLSession.shared.upload(
                data: try $0.soapEncoded(),
                with: try $0.soapURLRequest(endpoint: endpoint)
            )
        }.then { arg0 -> Int in
            let (data, response) = arg0
            let decoder = XMLDecoder()
            decoder.shouldProcessNamespaces = true

            if response.statusCode == 200 {
                // If WANIPConnection v1 we return requested port
                guard version > 1 else {
                    return port
                }
                // If WANIPConnection v2+ we return response port
                let response = try decoder.decode(UPnPActionResponse.self, from: data)
                return response.reservedPort
            } else if response.statusCode == 500 {
                throw try decoder.decode(UPnPActionError.self,from: data)
            } else {
                throw BoatError.invalidActionResponse
            }
        }
    }

    public static func addPortMapping(for port: Int, programName: String) -> Promise<Int> {
        // Try WANIPConnection v2
        let version2 = 2
        let portPromiseV2 = endpoint(forService: .wanIPConnection(version2))
        .then {
            (endpoint: $0, version: version2)
        }

        // Try WANIPConnection v1
        let version1 =  1
        let portPromiseV1 = endpoint(forService: .wanIPConnection(version1))
        .then {
            (endpoint: $0, version: version1)
        }

        // Race endpoint result for WANIPConnection v1 & v2
        return race([portPromiseV2, portPromiseV1]).then {
            let (endpoint, version) = $0
            return requestMapping(
                forPort: port,
                endpoint: endpoint,
                programName: programName,
                version: version
            )
        }
    }
}

public enum BoatError: Error {
    case unknown(_ message: String)
    case invalidURL
    case unreachableEndpoint
    case invalidActionResponse
    case noDataReceived(url: String, code: Int)
    case notHttpResponse(url: String)
    case serviceNotFound
    case malformedData
    case corruptedData
    case invalidEnumValue
}
