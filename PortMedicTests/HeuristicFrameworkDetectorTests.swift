//
//  HeuristicFrameworkDetectorTests.swift
//  PortMedicTests
//
//  Created by bansikah on 24/08/2026.
//

import XCTest
@testable import PortMedic

final class HeuristicFrameworkDetectorTests: XCTestCase {
    private let detector = HeuristicFrameworkDetector()

    private func process(port: Int, name: String) -> PortProcessInfo {
        PortProcessInfo(pid: 1, port: port, transportProtocol: .tcp, processName: name, user: "joetec")
    }

    func test_detectsSpringBootFromJavaProcess() {
        let badge = detector.badge(for: process(port: 8080, name: "java"))
        XCTAssertEqual(badge?.label, "Spring Boot")
    }

    func test_detectsNextJsFromNodeOnPort3000() {
        let badge = detector.badge(for: process(port: 3000, name: "node"))
        XCTAssertEqual(badge?.label, "Next.js")
    }

    func test_detectsGenericNodeOnOtherPorts() {
        let badge = detector.badge(for: process(port: 4000, name: "node"))
        XCTAssertEqual(badge?.label, "Node.js")
    }

    func test_portHintTakesPrecedenceOverProcessName() {
        let badge = detector.badge(for: process(port: 5432, name: "postgres"))
        XCTAssertEqual(badge?.label, "PostgreSQL")
    }

    func test_returnsNilForUnknownProcess() {
        let badge = detector.badge(for: process(port: 9999, name: "mystery-daemon"))
        XCTAssertNil(badge)
    }
}
