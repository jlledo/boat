import Foundation
import Network
import Promises
import Version
import XMLCoder

public struct Boat {
    public static let packageName = "Boat"
    public static let packageVersion = Version(major: 0, minor: 1)

    static let osName = "macOS"

    static var userAgent: ProductIdentifier {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return ProductIdentifier(
            "\(Self.osName)/\(osVersion.majorVersion).\(osVersion.minorVersion) " +
            "UPnP/2.0 " +
            "\(Self.packageName)/\(packageVersion)"
        )!
    }

    static let upnpURNNamespace = "schemas-upnp-org"

//    var timers: [PortMappingRequest: Timer] = [:]

    static func endpoint(
        forService serviceType: ServiceType,
        matchVersion: Bool = false
    ) -> Promise<URL> {
        let descriptionURLPromise = DeviceFinder(
            target: .service(serviceType),
            friendlyName: "Boat",
            uuid: nil
        ).search().then { responses -> URL in
            // FIXME: Should check responses received and use another error
            guard let response = responses.first else {
                throw DiscoveryError.tooManyGateways
            }
            return response.location
        }

        let baseURLPromise = descriptionURLPromise.then { url -> URLComponents in
            var components = URLComponents()
            components.scheme = url.scheme
            components.host = url.host
            components.port = url.port
            return components
        }

        let controlURLPromise = descriptionURLPromise.then {
            URLSession.shared.fetchData(from: $0)
        // This download should take less than 1 second
        // However timeout starts ticking at promise definition
        // So we need to add it onto descriptionURLPromise's timeout
        }.timeout(20).then { arg0 -> URLComponents in
            let description = try XMLDecoder().decode(UPnPDeviceDescription.self, from: arg0.data)
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

        let portMapping = PortMapping(
            from: port,
            to: port,
            description: programName,
            gatewayHost: gatewayHost
        )

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
