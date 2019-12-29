import Socket

extension Socket.Address {
    /// The SSDP multicast address (239.255.255.250:1900).
    static let ssdpMulticast = Socket.createAddress(for: "239.255.255.250", on: 1900)!
}
