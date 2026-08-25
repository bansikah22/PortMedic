//
//  ProcessDetails.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// Extended, on-demand information about a process, shown in the detail panel.
struct ProcessDetails: Equatable {
    var executablePath: String?
    var workingDirectory: String?
}
