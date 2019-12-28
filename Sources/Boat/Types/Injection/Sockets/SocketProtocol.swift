import Foundation
import Socket

protocol SocketProtocol {
    func close()
    @discardableResult func write(from data: Data, to address: Socket.Address) throws -> Int
    func readDatagram(into data: inout Data) throws -> (bytesRead: Int, address: Socket.Address?)
    func setReadTimeout(value: UInt) throws
}

extension Socket: SocketProtocol {}
