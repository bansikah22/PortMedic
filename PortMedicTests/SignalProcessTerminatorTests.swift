//
//  SignalProcessTerminatorTests.swift
//  PortMedicTests
//
//  Created by bansikah on 25/08/2026.
//

import XCTest
@testable import PortMedic

final class SignalProcessTerminatorTests: XCTestCase {
    private let terminator = SignalProcessTerminator()

    func test_rejectsPIDZero_whichWouldSignalTheWholeProcessGroup() {
        XCTAssertFalse(SignalProcessTerminator.isSafeTarget(0))
        XCTAssertThrowsError(try terminator.forceTerminate(pid: 0))
    }

    func test_rejectsNegativePIDs_whichWouldSignalEveryReachableProcess() {
        for pid in [pid_t(-1), pid_t(-42)] {
            XCTAssertFalse(SignalProcessTerminator.isSafeTarget(pid))
            XCTAssertThrowsError(try terminator.forceTerminate(pid: pid))
        }
    }

    func test_rejectsLaunchd() {
        XCTAssertFalse(SignalProcessTerminator.isSafeTarget(1))
        XCTAssertThrowsError(try terminator.terminate(pid: 1))
    }

    func test_rejectsOwnProcess() {
        XCTAssertFalse(SignalProcessTerminator.isSafeTarget(getpid()))
        XCTAssertThrowsError(try terminator.forceTerminate(pid: getpid()))
    }

    func test_allowsOrdinaryPID() {
        XCTAssertTrue(SignalProcessTerminator.isSafeTarget(getpid() + 1))
    }
}
