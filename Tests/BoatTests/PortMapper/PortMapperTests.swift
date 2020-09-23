import XCTest

@testable import Boat

final class PortMapperTests: XCTestCase {
    func testPortMapper() {
        let mapper = PortMapper(friendlyName: "PortMapperTests")
        let delegate = PortMapperTestDelegate(mapper: mapper)
        mapper.delegate = delegate

        let validPortRange = 1024..<65536
        mapper.addMapping(for: Int.random(in: validPortRange))

        wait(for: [expectation(description: "")], timeout: 10000.0)
    }
}
