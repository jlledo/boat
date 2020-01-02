import Promises
import Socket
import XCTest

@testable import Boat

final class DeviceFinderTests: XCTestCase {
    private static let timeoutFudgeFactor: Double = 1.5

    private func wait(for expectation: XCTestExpectation, timeout seconds: Int) {
        wait(for: [expectation], timeout: Double(seconds) * Self.timeoutFudgeFactor)
    }

    func testSearchReturnsValidResponses() {
        let expectation = XCTestExpectation(description: "Return 2 SSDP search responses")
        let searchTimeout = 1
        let finder = DeviceFinder(
            timeout: searchTimeout,
            target: .all,
            friendlyName: "BoatTests",
            uuid: nil,
            socketProvider: SocketProviderMock.self
        )
        _ = finder.search().then {
            if $0.count == 2 {
                expectation.fulfill()
            }
        }

        wait(for: expectation, timeout: searchTimeout)
    }

    func testSearchIgnoresInvalidResponses() {
        let expectation = XCTestExpectation(description: "Return 1 SSDP search response")
        let searchTimeout = 1
        let finder = DeviceFinder(
            timeout: searchTimeout,
            target: .all,
            friendlyName: "BoatTests",
            uuid: nil,
            socketProvider: ErrorSocketProviderMock.self
        )
        _ = finder.search().then {
            if $0.count == 1 {
                expectation.fulfill()
            }
        }

        wait(for: expectation, timeout: searchTimeout)
    }
}
