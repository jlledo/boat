enum SSDPMessageType: String {
    case advertisement = "NOTIFY * HTTP/1.1"
    case searchRequest = "M-SEARCH * HTTP/1.1"
    case searchResponse = "HTTP/1.1 200 OK"
}
