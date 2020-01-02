class SocketProviderMockHelpers {
    private init() {}

    static let validSSDPSearchResponse =
        "HTTP/1.1 200 OK\r\n" +
        "CACHE-CONTROL: max-age=0\r\n" +
        "EXT:\r\n" +
        "LOCATION: http://0.0.0.0\r\n" +
        "SERVER: TEST_OS/0.0 UPnP/2.0 BoatTests/0.0.0\r\n" +
        "ST: ssdp:all\r\n" +
        // TODO: Use a syntactically valid UUID
        "USN: uuid:\r\n" +
        "\r\n"
}
