import Foundation
import Socket

@testable import Boat

class SocketMock: SocketProtocol {
    private var messagesToRead: [String]

    var isClosed: Bool = false

    var writeCount: Int = 0
    var lastDataWritten: Data?
    var lastWriteAddress: Socket.Address?

    var readMessageCount: Int = 0
    var readTimeout: Double?

    init(messagesToRead: [String]) {
        self.messagesToRead = messagesToRead
    }

    func close() {
        isClosed = true
    }

    func write(from data: Data, to address: Socket.Address) throws -> Int {
        lastDataWritten = data
        lastWriteAddress = address
        writeCount += 1

        return -1
    }

    func readDatagram(into data: inout Data) throws -> (bytesRead: Int, address: Socket.Address?) {
        guard readTimeout != nil else {
            throw DiscoveryTestError.timeoutNotSet
        }
        guard !messagesToRead.isEmpty else {
            Thread.sleep(forTimeInterval: readTimeout ?? 0.0)
            errno = EAGAIN
            return (0, nil)
        }

        data = Data(messagesToRead.removeFirst().utf8)

        readMessageCount += 1

        return (data.count, Socket.createAddress(for: "0.0.0.0", on: 0))
    }

    func setReadTimeout(value: UInt) {
        readTimeout = Double(value) / 1000.0
    }
}
