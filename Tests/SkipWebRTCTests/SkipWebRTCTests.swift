import XCTest
#if canImport(AndroidLogging)
import AndroidLogging
#else
import OSLog
#endif
import Foundation
@testable import SkipWebRTC

let logger: Logger = Logger(subsystem: "SkipWebRTC", category: "Tests")

@available(macOS 13, *)
final class SkipWebRTCTests: XCTestCase {
    
    func testSkipWebRTC() throws {
        logger.log("running testSkipWebRTC")
        XCTAssertEqual(1 + 2, 3, "basic test")
    }
    
    #if SKIP
    func testDecodeType() throws {
        // load the TestData.json file from the Resources folder and decode it into a struct
        let resourceURL: URL = try XCTUnwrap(Bundle.module.url(forResource: "TestData", withExtension: "json"))
        let testData = try JSONDecoder().decode(TestData.self, from: Data(contentsOf: resourceURL))
        XCTAssertEqual("SkipWebRTC", testData.testModuleName)
    }
    
    // Test to validate types and interfaces
    func testWebRTCTypes() throws {
        // Test enum exists with correct cases
        let state = SkipIceConnectionState.new
        XCTAssertEqual(state.rawValue, 0)
        
        let checkingState = SkipIceConnectionState.checking
        XCTAssertEqual(checkingState.rawValue, 1)
        
        // Test fromOrdinal functionality
        let derivedState = SkipIceConnectionState.fromOrdinal(3)
        XCTAssertEqual(derivedState, .completed)
        
        // Test struct initialization
        let candidate = SkipIceCandidate(sdpMid: "test", sdpMLineIndex: 1, sdp: "sdp-data")
        XCTAssertEqual(candidate.sdpMid, "test")
        XCTAssertEqual(candidate.sdpMLineIndex, 1)
        XCTAssertEqual(candidate.sdp, "sdp-data")
        
        let sessionDesc = SkipSessionDescription(type: "offer", sdp: "session-data")
        XCTAssertEqual(sessionDesc.type, "offer")
        XCTAssertEqual(sessionDesc.sdp, "session-data")
    }
    #endif
    
    
}

struct TestData : Codable, Hashable {
    var testModuleName: String
}
