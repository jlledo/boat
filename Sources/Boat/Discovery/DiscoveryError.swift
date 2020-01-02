enum DiscoveryError: Error {
    case unexpectedMessageType(expected: String, found: String)
    case missingRequiredHeader(String)
    case invalidHeader(String)
    case incompatibleHeaderType(type: String, header: String)
    case searchResponseTimeout(UInt)
    case gatewayNotFound
    case tooManyGateways
}
