import Socket

@testable import Boat

struct ErrorSocketProviderMock: SocketProviderProtocol {
    static func create(
        family: Socket.ProtocolFamily,
        type: Socket.SocketType,
        proto: Socket.SocketProtocol
    ) throws -> SocketProtocol {
        return SocketMock(messagesToRead: [
            SocketProviderMockHelpers.validSSDPSearchResponse,
            "========ERROR========",
        ])
    }
}
