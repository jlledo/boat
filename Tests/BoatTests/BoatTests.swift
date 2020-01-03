import XCTest
@testable import Boat
import Network
import Promises
import XMLCoder

final class BoatTests: XCTestCase {
    func testAddPortMapping() {
        let expectation = XCTestExpectation(description: "Add random valid port mapping")

        let validPortRange = 1024..<65536
        _ = Boat.addPortMapping(
            for: Int.random(in: validPortRange),
            programName: "BoatTests"
        ).then {
            XCTAssert(validPortRange ~= $0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testAddPortMappingUnauthorized() {
        let expectaction = XCTestExpectation(description: "Fail to add invalid port mapping")

        _ = Boat.addPortMapping(for: 123, programName: "BoatTests").catch {
            XCTAssertEqual($0 as? UPnPActionError, UPnPActionError.actionNotAuthorized)
        }

        wait(for: [expectaction], timeout: 5.0)
    }

    func testLocalAddressForHost() {
        let expectation = XCTestExpectation(description: "Get local address for common router IP")

        _ = Interface.localAddress(forHost: Host("192.168.1.1")).then { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testPortMappingControlMessageEncoding() {
        let expectation = XCTestExpectation(
            description: "Build port mapping control message without errors"
        )

        let port = 1024
        let mapping = PortMapping(
            from: port,
            to: port,
            description: "",
            gatewayHost: "192.168.1.1"
        )
        _ = mapping.asControlMessage(forVersion: 1).then {
            _ = try $0.soapEncoded()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testDeviceTypeFromDecoderStandard() {
        let string = "<value>urn:schemas-upnp-org:device:InternetGatewayDevice:2</value>"
        let deviceType = try! XMLDecoder().decode(
            DeviceType.self,
            from: Data(string.utf8)
        )

        XCTAssertEqual(deviceType, .internetGatewayDevice(2))
    }

    func testDeviceTypeFromDecoderVendor() {
        let string = "<value>urn:example-vendor.org:device:CoolDevice:4</value>"
        let deviceType = try! XMLDecoder().decode(
            DeviceType.self,
            from: Data(string.utf8)
        )

        XCTAssertEqual(deviceType, .unsupported(
            namespace: "example-vendor.org",
            name: "CoolDevice",
            version: 4
        ))
    }

    func testSearchGateway() {
        let expectation = XCTestExpectation(description: "Get gateway device description")
        _ = DeviceFinder.searchGateway(friendlyName: "BoatTests").then { _ in
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 4.0)
    }

    func testEndpointForService() {
        let expectation = XCTestExpectation(description: "Get endpoint for WANIPConnection:1")
        _ = Boat.endpoint(forService: .wanIPConnection(1)).then { _ in 
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testServiceTypeEquatable() {
        let service1 = ServiceType.wanIPConnection(2)
        let service2 = ServiceType.wanIPConnection(2)
        XCTAssertEqual(service1, service2)

        let service3 = ServiceType.wanIPConnection(1)
        XCTAssertNotEqual(service1, service3)
    }

    func testServiceTypeIsCompatible() {
        let service1 = ServiceType.wanIPConnection(2)
        let service2 = ServiceType.wanIPConnection(2)
        XCTAssert(service1.isCompatible(with: service2))
        XCTAssert(service2.isCompatible(with: service1))

        let service3 = ServiceType.wanIPConnection(1)
        XCTAssert(service1.isCompatible(with: service3))
        XCTAssert(!service3.isCompatible(with: service1))
    }

    func testDeviceTypeFromString() {
        let deviceString = "urn:schemas-upnp-org:device:InternetGatewayDevice:2"
        let deviceType = DeviceType(deviceString)
        XCTAssertNotNil(deviceType)
    }

    func testServiceTypeFromString() {
        let serviceString = "urn:schemas-upnp-org:service:WANIPConnection:2"
        let serviceType = ServiceType(serviceString)
        XCTAssertNotNil(serviceType)
    }

    func testRFC1123DateFormatter() {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        XCTAssertNotNil(dateFormatter.date(from: "Mon, 01 Jan 2001 00:00:00 GMT"))
    }

    static var allTests = [
        ("testAddPortMapping", testAddPortMapping),
        ("testAddPortMappingUnauthorized", testAddPortMappingUnauthorized),
        ("testLocalAddressForHost", testLocalAddressForHost),
        ("testPortMappingControlMessageEncoding", testPortMappingControlMessageEncoding),
        ("testDeviceTypeFromDecoderStandard", testDeviceTypeFromDecoderStandard),
        ("testDeviceTypeFromDecoderVendor", testDeviceTypeFromDecoderVendor),
        ("testSearchGateway", testSearchGateway),
        ("testEndpointForService", testEndpointForService),
        ("testServiceTypeEquatable", testServiceTypeEquatable),
        ("testServiceTypeIsCompatible", testServiceTypeIsCompatible),
        ("testDeviceTypeFromString", testDeviceTypeFromString),
        ("testServiceTypeFromString", testServiceTypeFromString),
        ("testRFC1123DateFormatter", testRFC1123DateFormatter),
    ]
}
