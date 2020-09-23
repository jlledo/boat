@testable import Boat

class PortMapperTestDelegate: PortMapperDelegateProtocol {
    let mapper: PortMapper

    init(mapper: PortMapper) {
        self.mapper = mapper
    }

    func didAddPortMapping(requestedPort: Int, reservedPort: Int) {
        print("REQUESTED: \(requestedPort),\tRESERVED: \(reservedPort)")
    }

    func addPortMapping(forPort port: Int, failedWith error: Error) {
        print("REQUESTED: \(port),\tERROR: \(error)")
    }
}
