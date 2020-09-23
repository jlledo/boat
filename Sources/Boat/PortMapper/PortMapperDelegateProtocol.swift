protocol PortMapperDelegateProtocol: AnyObject {
    func didAddPortMapping(requestedPort: Int, reservedPort: Int)
    func addPortMapping(forPort port: Int, failedWith error: Error)
}
