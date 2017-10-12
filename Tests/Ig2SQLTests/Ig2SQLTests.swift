import Foundation
import XCTest
//import Files
import Ig2SQLCore

class Ig2SQLTests: XCTestCase {
    func testCommandProcessing() throws {
            XCTAssertNil(CommandHandler.processargs( argv: CommandLine.arguments))
        
    }
}
