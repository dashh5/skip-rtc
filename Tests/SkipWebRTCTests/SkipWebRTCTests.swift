import XCTest
import OSLog
import Foundation
@testable import SkipWebRTC

let logger: Logger = Logger(subsystem: "SkipWebRTC", category: "Tests")

@available(macOS 13, *)
final class SkipWebRTCTests: XCTestCase {

    func testSkipWebRTC() throws {
        logger.log("running testSkipWebRTC")
        XCTAssertEqual(1 + 2, 3, "basic test")
    }

    func testDecodeType() throws {
        // load the TestData.json file from the Resources folder and decode it into a struct
        let resourceURL: URL = try XCTUnwrap(Bundle.module.url(forResource: "TestData", withExtension: "json"))
        let testData = try JSONDecoder().decode(TestData.self, from: Data(contentsOf: resourceURL))
        XCTAssertEqual("SkipWebRTC", testData.testModuleName)
    }

//    func testPeerConnection() {
//        let skipWebRTC = SkipWebRTCModule(iceServers: ["stun:stun.l.google.com:19302"])
//        
//        let expectation = XCTestExpectation(description: "Offer created")
//        skipWebRTC.offer { sdp in
//            XCTAssertNotNil(sdp)
//            XCTAssertFalse(sdp.sdp.isEmpty)
//            expectation.fulfill()
//        }
//        
//        wait(for: [expectation], timeout: 5.0)
//    }
//    
//    func testMuteAudio() {
//        let skipWebRTC = SkipWebRTCModule(iceServers: ["stun:stun.l.google.com:19302"])
//        skipWebRTC.muteAudio() // Basic test; expand with assertions if needed
//    }

}

struct TestData : Codable, Hashable {
    var testModuleName: String
}
