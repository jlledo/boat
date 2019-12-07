struct UPnPActionResponse {
    let reservedPort: Int
}

extension UPnPActionResponse: Decodable {
    init(from decoder: Decoder) throws {
        let envelope = try decoder.container(keyedBy: DynamicKey.self)
        let body = try envelope.nestedContainer(keyedBy: DynamicKey.self, forKey: "Body")
        let actionResponse = try body.nestedContainer(
            keyedBy: DynamicKey.self,
            forKey: "AddAnyPortMappingResponse"
        )
        reservedPort = try actionResponse.decode(Int.self, forKey: "NewReservedPort")
    }
}
