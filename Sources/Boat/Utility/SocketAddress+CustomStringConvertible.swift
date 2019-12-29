import Darwin.POSIX.netinet.`in`
import Socket

extension Socket.Address: CustomStringConvertible {
    public var description: String {
        switch self {
        case .ipv4(var address):
            var addressCString = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            inet_ntop(AF_INET, &address.sin_addr, &addressCString, socklen_t(INET_ADDRSTRLEN))
            // Convert port to network order (big endian)
            return "\(String(cString: &addressCString)):\(address.sin_port.bigEndian)"

        case .ipv6(var address):
            var addressCString = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            inet_ntop(AF_INET6, &address.sin6_addr, &addressCString, socklen_t(INET6_ADDRSTRLEN))
            // Convert port to network order (big endian)
            return "\(String(cString: &addressCString)):\(address.sin6_port.bigEndian)"

        case .unix(var address):
            let pathCString = [CChar](UnsafeBufferPointer(
                start: &address.sun_path.0,
                count: MemoryLayout.size(ofValue: address.sun_path)
            ))
            return String(cString: pathCString)
        }
    }
}
