import Foundation
import Promises
import XMLCoder

public class PortMapper {
    let friendlyName: String

    weak var delegate: PortMapperDelegateProtocol?

    // MARK: - Gateway variables

    private var gateway: GatewayDevice?

    /// Timer to set gateway to nil on cache expiry
    private var gatewayInvalidationTimer: Timer?

    /// Timer to renew gateway information
    private var gatewayRenewalTimer: Timer?

    private var privateIPAddress: String?

    // MARK: - Requested port mappings

    private var unprocessedMappings: Set<Int> = []

    private var processMappingsTimer: Timer?

    private var mappingTimersByPort: [Int: Timer] = [:]

    private var testTimer: Timer!

    // MARK: - Dependency Injection

    private let urlSession: URLSession

    // MARK: -

    public init(friendlyName: String, urlSession: URLSession = .shared) {
        self.friendlyName = friendlyName
        self.urlSession = urlSession
        self.processMappingsTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
            self?.processMappings()
        }

//        self.testTimer = Timer.scheduledTimer(
//            withTimeInterval: 1.0,
//            repeats: true
//        ) { [weak self] _ in
//            self?.getMapping(0).then {
//                print(String(describing: $0))
//            }.catch {
//                print($0)
//            }
//        }

        refreshGateway()
    }

    deinit {
        // Invalidate leftover timers
        gatewayInvalidationTimer?.invalidate()
        gatewayRenewalTimer?.invalidate()
        processMappingsTimer?.invalidate()
        testTimer.invalidate()
        for timer in mappingTimersByPort.values {
            timer.invalidate()
        }
    }

    private func gatewayOrThrow() throws -> GatewayDevice {
        guard let gateway = self.gateway else {
            throw DiscoveryError.gatewayNotFound
        }
        return gateway
    }

    private func privateIPAddressOrThrow() throws -> String {
        guard let address = self.privateIPAddress else {
            throw DiscoveryError.gatewayNotFound
        }
        return address
    }

    private func savePrivateIPAddress(gatewayResponse: SSDPSearchResponse) {
        Interface.localAddress(
            forHost: Host(gatewayResponse.location.host!),
            port: Port(rawValue: UInt16(gatewayResponse.location.port!))!
        ).then {
            self.privateIPAddress = $0
            print("Saved new private IP address")
        }
    }

    private func getDescriptionWithLatestServiceVersion(
        searchResponses: [SSDPSearchResponse]
    ) -> Promise<(SSDPSearchResponse, UPnPDeviceDescription)> {
        var promises: [Promise<(data: Data, response: HTTPURLResponse)>] = []
        for response in searchResponses {
            promises.append(self.urlSession.fetchData(from: response.location))
        }

        return all(promises).then {
            (descriptionResponses) -> (SSDPSearchResponse, UPnPDeviceDescription) in
            print("Received description responses")
            let descriptions = descriptionResponses.map {
                try? XMLDecoder().decode(UPnPDeviceDescription.self, from: $0.data)
            }

            var maxVersion: Int = 0
            var maxVersionGatewayInfo: (SSDPSearchResponse, UPnPDeviceDescription)? = nil
            for pair in zip(searchResponses, descriptions) {
                let (response, descriptionOptional) = pair
                guard let description = descriptionOptional,
                      let service = description.findService(ofType: .wanIPConnection(1)) else {
                    continue
                }
                if case .wanIPConnection(let version) = service.type {
                    if version > maxVersion {
                        maxVersion = version
                        maxVersionGatewayInfo = (response, description)
                    }
                }
            }
            guard let gatewayInfo = maxVersionGatewayInfo else {
                throw DiscoveryError.gatewayNotFound
            }
            return gatewayInfo
        }
    }

    func refreshGateway() {
        print("Entered refreshGateway()")
        var searchResponseDate: Date! = nil
        DeviceFinder.searchGateway(friendlyName: friendlyName).then {
            (responses) -> Promise<(SSDPSearchResponse, UPnPDeviceDescription)> in
            searchResponseDate = Date()
            return self.getDescriptionWithLatestServiceVersion(searchResponses: responses)
        }.then { arg0 in
            let (searchResponse, deviceDescription) = arg0
            // Save LAN interface private IP address
            self.savePrivateIPAddress(gatewayResponse: searchResponse)

            self.gateway = GatewayDevice(
                description: deviceDescription,
                descriptionURL: searchResponse.location
            )
            print("Saved new gateway device")

            print("Setting new timers")
            // Disable old timers
            self.gatewayInvalidationTimer?.invalidate()
            self.gatewayRenewalTimer?.invalidate()

            // Set new timers
            let timeElapsed = Date().timeIntervalSince(searchResponseDate)
            self.gatewayInvalidationTimer = Timer.scheduledTimer(
                withTimeInterval: TimeInterval(searchResponse.cacheValidity) - timeElapsed,
                repeats: false
            ) { [weak self] _ in
                print("Gateway expired")
                self?.gateway = nil
                self?.privateIPAddress = nil
            }

            let refreshTimeout = max(searchResponse.cacheValidity - 30, 0)
            self.gatewayRenewalTimer = Timer.scheduledTimer(
                withTimeInterval: TimeInterval(refreshTimeout) - timeElapsed,
                repeats: false
            ) { [weak self] _ in
                self?.refreshGateway()
            }
        }.catch { _ in
            self.refreshGateway()
        }
    }

    private func controlMessage(forPort port: Int) throws -> UPnPControlMessage {
        let privateIPAddress = try privateIPAddressOrThrow()
        let serviceVersion = try gatewayOrThrow().service.type.version

        return PortMapping(
            externalPort: port,
            internalPort: port,
            internalClient: privateIPAddress,
            description: self.friendlyName
        ).asControlMessage(
            forVersion: serviceVersion
        )
    }

    private func urlRequest(forMessage message: UPnPControlMessage) throws -> URLRequest {
        let gateway = try gatewayOrThrow()

        var endpointComponents = URLComponents()
        endpointComponents.scheme = gateway.descriptionURL.scheme
        endpointComponents.host = gateway.descriptionURL.host
        endpointComponents.port = gateway.descriptionURL.port
        endpointComponents.path = gateway.service.controlURL.path
        guard let endpoint = endpointComponents.url else {
            throw BoatError.invalidURL
        }

        return try message.soapURLRequest(endpoint: endpoint)
    }

    private func scheduleProcessMappings() {
        guard processMappingsTimer == nil else { return }
        processMappingsTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: false
        ) { [weak self] _ in
            self?.processMappings()
        }
    }

    private func processMappings() {
        print("Started processing new mappings")
        let mappingsToProcess = self.unprocessedMappings
        self.unprocessedMappings.removeAll()

        var controlPromises: [Promise<(data: Data, response: HTTPURLResponse)>] = []
        var failedMappings: Set<Int> = []
        for port in mappingsToProcess {
            let promise = Promise { () -> (Data, URLRequest) in
                let portMappingControlMessage = try self.controlMessage(forPort: port)
                let messageData = try portMappingControlMessage.soapEncoded()
                let urlRequest = try self.urlRequest(forMessage: portMappingControlMessage)
                return (messageData, urlRequest)
            }.then(self.urlSession.upload).then {
                (arg0) -> Void in
                let (data, response) = arg0
                let decoder = XMLDecoder()
                decoder.shouldProcessNamespaces = true

                guard response.statusCode == 200 else {
                    let error: Error =
                        (try? decoder.decode(UPnPActionError.self,from: data)) ??
                        BoatError.invalidActionResponse
                    self.delegate?.addPortMapping(forPort: port, failedWith: error)
                    throw error
                }

                let actionResponse = try? decoder.decode(UPnPActionResponse.self, from: data)
                let reservedPort = actionResponse?.reservedPort ?? port
                self.delegate?.didAddPortMapping(requestedPort: port,reservedPort: reservedPort)
            }.catch { _ in
                failedMappings.insert(port)
                
            }
            controlPromises.append(promise)
        }
        all(controlPromises).catch { _ in
            self.unprocessedMappings.formUnion(failedMappings)
            self.processMappings()
        }
        if self.unprocessedMappings.isEmpty {
            self.processMappingsTimer?.invalidate()
            self.processMappingsTimer = nil
        }
    }

    func addMapping(for port: Int) {
        unprocessedMappings.insert(port)
        if self.processMappingsTimer == nil {
            self.processMappingsTimer = Timer.scheduledTimer(
                withTimeInterval: 1.0,
                repeats: true
            ) { [weak self] _ in
                self?.processMappings()
            }
        }
    }

    func getMapping(_ index: Int) -> Promise<PortMapping> {
        return Promise { () -> Promise<(data: Data, response: HTTPURLResponse)> in
            let serviceVersion = self.gatewayOrThrow().service.type.version
            let action = GetGenericPortMappingEntry(index)
            let controlMessage = action.asControlMessage(forVersion: serviceVersion)
            guard let messageData = try? controlMessage.soapEncoded(),
                let urlRequest = self.urlRequest(forMessage: controlMessage)
            else {
                throw BoatError.corruptedData
            }

            return self.urlSession.upload(data: messageData, with: urlRequest)
        }.then { (data: Data, response: HTTPURLResponse) -> PortMapping in
            let decoder = XMLDecoder()
            decoder.shouldProcessNamespaces = true

            guard response.statusCode == 200 else {
                let error: Error =
                    (try? decoder.decode(UPnPActionError.self,from: data)) ??
                    BoatError.invalidActionResponse
                throw error
            }

            print("SUCCESS")
            return PortMapping(externalPort: 0, internalPort: 0, internalClient: "", description: "")
        }
    }
}
