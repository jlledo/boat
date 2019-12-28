import Foundation
import XMLCoder

struct UPnPActionInvocation {
    let action: UPnPActionURN
    let arguments: [(String, AnyEncodable)]

    static var rootKey: String {
        "\(Self.envelopeNamespaceKey):Envelope"
    }

    private static let envelopeNamespaceKey: String = "s"
    private static let envelopeNamespaceValue: String = "http://schemas.xmlsoap.org/soap/envelope/"
    private static let encodingStyle = "http://schemas.xmlsoap.org/soap/encoding/"
    private static let actionNamespaceKey: String = "u"
}

extension UPnPActionInvocation: Encodable {
    func encode(to encoder: Encoder) throws {
        var envelope = encoder.container(keyedBy: DynamicKey.self)
        try envelope.encode(
            Self.envelopeNamespaceValue,
            forKey: DynamicKey("xmlns:\(Self.envelopeNamespaceKey)")
        )
        try envelope.encode(
            Self.encodingStyle,
            forKey: DynamicKey("\(Self.envelopeNamespaceKey):encodingStyle")
        )

        var body = envelope.nestedContainer(
            keyedBy: DynamicKey.self,
            forKey: DynamicKey("\(Self.envelopeNamespaceKey):Body")
        )
        var action = body.nestedContainer(
            keyedBy: DynamicKey.self,
            forKey: DynamicKey("\(Self.actionNamespaceKey):\(self.action.name)")
        )
        try action.encode(
            String(describing: self.action.objectType),
            forKey: DynamicKey("xmlns:\(Self.actionNamespaceKey)")
        )

        for (argument, value) in arguments {
            try action.encode(value, forKey: DynamicKey(argument))
        }
    }
}

extension UPnPActionInvocation: DynamicNodeEncoding {
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        if key.stringValue == "xmlns:\(Self.envelopeNamespaceKey)" ||
            key.stringValue == "xmlns:\(Self.actionNamespaceKey)" ||
            key.stringValue == "\(Self.envelopeNamespaceKey):encodingStyle" {
            return .attribute
        }

        return .element
    }
}

extension UPnPActionInvocation {
    func soapEncoded() throws -> Data {
        let header = XMLHeader(version: 1.0)
        return try XMLEncoder().encode(self, withRootKey: Self.rootKey, header: header)
    }



    func soapURLRequest(endpoint: URL) throws -> URLRequest {
        guard let host = endpoint.host, let port = endpoint.port else {
            throw BoatError.invalidURL
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"

        request.setValue("\(host):\(port)", forHTTPHeaderField: "HOST")
        request.setValue(#"text/xml; charset="utf-8""#, forHTTPHeaderField: "CONTENT-TYPE")
        request.setValue("\"\(String(describing: action))\"", forHTTPHeaderField: "SOAPACTION")
        request.setValue(Boat.userAgent, forHTTPHeaderField: "USER-AGENT")

        return request
    }
}
