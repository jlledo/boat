import Socket

struct SocketProvider: SocketProviderProtocol {
    static func create(
        family: Socket.ProtocolFamily,
        type: Socket.SocketType,
        proto: Socket.SocketProtocol
    ) throws -> SocketProtocol {
        return try Socket.create(family: family, type: type, proto: proto)
    }
}
