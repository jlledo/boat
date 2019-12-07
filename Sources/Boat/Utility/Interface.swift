import Darwin
import Network
import Promises

class Interface {
    private init() {}

    enum AddressFamily: Int {
        case ipv4 = 2 // AF_INET
        case ipv6 = 30 // AF_INET6
    }

    // Slightly modified https://stackoverflow.com/a/25627545
    static func localAddressesByInterface(
        for addressFamily: AddressFamily
    ) -> [String: String] {
        var addresses = [String: String]()

        // Get list of all interfaces on the local machine:
        var ifAddrs: UnsafeMutablePointer<ifaddrs>?
        let result = getifaddrs(&ifAddrs)
        defer { freeifaddrs(ifAddrs) }
        guard result == 0, let firstAddr = ifAddrs else { return [:] }

        // For each interface ...
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee

            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if ((flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING)) &&
                (addr.sa_family == UInt8(addressFamily.rawValue)) {

                // Convert interface address to a human readable string:
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(
                    ptr.pointee.ifa_addr,
                    socklen_t(addr.sa_len),
                    &hostname,
                    socklen_t(hostname.count),
                    nil,
                    socklen_t(0),
                    NI_NUMERICHOST
                ) == 0 {
                    let interfaceName = String(cString: ptr.pointee.ifa_name)
                    let address = String(cString: hostname)
                    addresses[interfaceName] = address
                }
            }
        }

        return addresses
    }

    static func localAddress(
        forHost host: NWEndpoint.Host,
        port: NWEndpoint.Port = .http,
        using parameters: NWParameters = .tcp
    ) -> Promise<String> {
        return Promise() { fulfill, reject in
            let connection = NWConnection(host: host, port: port, using: parameters)
            connection.pathUpdateHandler = { newPath in
                defer { connection.cancel() }

                guard !newPath.availableInterfaces.isEmpty else {
                        reject(BoatError.unreachableEndpoint)
                        return
                }

                let interface = newPath.availableInterfaces[0]
                let addresses = localAddressesByInterface(for: .ipv4)
                if let address = addresses[interface.name] {
                    fulfill(address)
                } else {
                    reject(BoatError.unreachableEndpoint)
                }
            }
            connection.start(queue: .global())
        }
    }
}
