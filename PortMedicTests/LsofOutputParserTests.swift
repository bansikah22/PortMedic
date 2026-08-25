//
//  LsofOutputParserTests.swift
//  PortMedicTests
//
//  Created by bansikah on 24/08/2026.
//

import XCTest
@testable import PortMedic

final class LsofOutputParserTests: XCTestCase {
    func test_parse_extractsTCPListeningProcess() {
        let output = """
        COMMAND   PID   USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        java     4512 joetec   23u  IPv6 0x1234      0t0  TCP *:8080 (LISTEN)
        """

        let result = LsofOutputParser.parse(output)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.pid, 4512)
        XCTAssertEqual(result.first?.port, 8080)
        XCTAssertEqual(result.first?.processName, "java")
        XCTAssertEqual(result.first?.user, "joetec")
        XCTAssertEqual(result.first?.transportProtocol, .tcp)
    }

    func test_parse_handlesLoopbackAddress() {
        let output = """
        COMMAND   PID   USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        postgres 1122 joetec    5u  IPv4 0x1234      0t0  TCP 127.0.0.1:5432 (LISTEN)
        """

        let result = LsofOutputParser.parse(output)

        XCTAssertEqual(result.first?.port, 5432)
    }

    func test_parse_handlesIPv6BracketAddress() {
        let output = """
        COMMAND   PID   USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        node     9211 joetec   12u  IPv6 0x1234      0t0  TCP [::1]:3000 (LISTEN)
        """

        let result = LsofOutputParser.parse(output)

        XCTAssertEqual(result.first?.port, 3000)
    }

    func test_parse_ignoresMalformedLines() {
        let output = """
        COMMAND   PID   USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        not enough columns here
        """

        let result = LsofOutputParser.parse(output)

        XCTAssertTrue(result.isEmpty)
    }

    func test_parse_returnsEmptyForEmptyOutput() {
        XCTAssertTrue(LsofOutputParser.parse("").isEmpty)
        XCTAssertTrue(LsofOutputParser.parse("COMMAND   PID   USER   FD   TYPE DEVICE SIZE/OFF NODE NAME").isEmpty)
    }

    func test_extractPort_returnsNilForMissingPort() {
        XCTAssertNil(LsofOutputParser.extractPort(from: "no-colon-here"))
    }

    func test_parse_rejectsNonPositivePIDs() {
        // kill(2) treats 0 as "this process group" and -1 as "every process the
        // user can signal", so such rows must never become killable targets.
        let output = """
        COMMAND   PID   USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        evil         0 joetec   23u  IPv4 0x1234      0t0  TCP *:8080 (LISTEN)
        evil        -1 joetec   23u  IPv4 0x1234      0t0  TCP *:8081 (LISTEN)
        """

        XCTAssertTrue(LsofOutputParser.parse(output).isEmpty)
    }

    func test_parse_rejectsOutOfRangePorts() {
        let output = """
        COMMAND   PID   USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
        weird     4512 joetec   23u  IPv4 0x1234      0t0  TCP *:0 (LISTEN)
        weird     4513 joetec   23u  IPv4 0x1234      0t0  TCP *:99999 (LISTEN)
        """

        XCTAssertTrue(LsofOutputParser.parse(output).isEmpty)
    }
}
