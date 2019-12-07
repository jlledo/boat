enum UPnPActionError: Int, Error {
    case unsupportedCode = -1

    // General Errors
    case invalidAction = 401
    case invalidArgs = 402
    case actionFailed = 501
    case argumentValueInvalid = 600
    case argumentValueOutOfRange = 601
    case optionalActionNotImplemented = 602
    case outOfMemory = 603
    case humanInterventionRequired = 604
    case stringArgumentTooLong = 605

    // WANIPConnection:2::AddAnyPortMapping() errors
    case actionNotAuthorized = 606
    case wildCardNotPermittedInSrcIP = 715
    case wildCardNotPermittedInExtPort = 716
    case noPortMapsAvailable = 728
    case conflictWithOtherMechanisms = 729
    case wildCardNotPermittedInIntPort = 732
}

extension UPnPActionError: Decodable {
    init(from decoder: Decoder) throws {
        let envelope = try decoder.container(keyedBy: DynamicKey.self)
        let body = try envelope.nestedContainer(keyedBy: DynamicKey.self, forKey: "Body")
        let fault = try body.nestedContainer(keyedBy: DynamicKey.self, forKey: "Fault")
        let detail = try fault.nestedContainer(keyedBy: DynamicKey.self, forKey: "detail")
        let error = try detail.nestedContainer(keyedBy: DynamicKey.self, forKey: "UPnPError")
        
        let code = try error.decode(Int.self, forKey: "errorCode")
        self = UPnPActionError(rawValue: code) ?? .unsupportedCode
    }
}
