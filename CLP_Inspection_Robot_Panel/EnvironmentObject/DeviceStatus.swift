//
//  DeviceStatus.swift
//  CLP_Inspection_Robot_Panel
//
//  Created by Kam Ho Leung on 26/5/2025.
//

import Foundation

class RobotStatus: Codable, ObservableObject, Equatable {
    var servo: [Int] = [1500, 1500, 1500, 1500]
    var relay: String = "00000000"
    var tof: [Int] = Array(repeating: 0, count: 18)
    var roll_angle: Int = 0
    var lazer: Int = 0
    var connected: Bool = false
    
    static func == (lhs: RobotStatus, rhs: RobotStatus) -> Bool {
        return lhs.servo == rhs.servo &&
            lhs.relay == rhs.relay &&
            lhs.tof == rhs.tof &&
            lhs.roll_angle == rhs.roll_angle &&
            lhs.lazer == rhs.lazer &&
            lhs.connected == rhs.connected
    }
}

class DigitalValve_Status: Codable, ObservableObject, Equatable {
    var pressure: [Double] = [0.0, 0.0, 0.0, 0.0]
    var connected: Bool = false
    
    static func == (lhs: DigitalValve_Status, rhs: DigitalValve_Status) -> Bool {
        return lhs.pressure == rhs.pressure &&
            lhs.connected == rhs.connected
    }
}

class LaunchPlatformStatus: Codable, ObservableObject, Equatable {
    var angle: Float = 1.0
    var relay: String = "00000000"
    var connected: Bool = false
    var setpoint: Float = 0
    var lazer: Int = 0
    
    static func == (lhs: LaunchPlatformStatus, rhs: LaunchPlatformStatus) -> Bool {
        return (lhs.angle*10).rounded() == (rhs.angle*10).rounded() &&
            lhs.relay == rhs.relay &&
            lhs.connected == rhs.connected &&
            lhs.setpoint == rhs.setpoint &&
            lhs.lazer == rhs.lazer
    }
}

class AutomationStatus: Codable, ObservableObject, Equatable {
    
    var sequence_name: String = ""
    var mode: String = "Manual"
    var action_update: String = ""
    var action_name: String = ""
    var tree_ascii: String = ""
    var connected: Bool = false
    
    static func == (lhs: AutomationStatus, rhs: AutomationStatus) -> Bool {
        return lhs.sequence_name == rhs.sequence_name &&
            lhs.mode == rhs.mode &&
            lhs.action_update == rhs.action_update &&
            lhs.action_name == rhs.action_name &&
            lhs.tree_ascii == rhs.tree_ascii &&
            lhs.connected == rhs.connected
    }
}

class AudioStatus: Codable, ObservableObject, Equatable {
    var recording: Bool = false
    var file_num: Int = 0
    var date: String = ""
    var slot: Int = 0
    var distance: Int = 0
    var FFT: [Float] = []
    var FFT_freq: [Float] = []
    var Audio: [Float] = []
    var connected: Bool = false
    
    static func == (lhs: AudioStatus, rhs: AudioStatus) -> Bool {
        return lhs.recording == rhs.recording &&
            lhs.file_num == rhs.file_num &&
            lhs.date == rhs.date &&
            lhs.slot == rhs.slot &&
            lhs.distance == rhs.distance &&
            lhs.FFT == rhs.FFT &&
            lhs.FFT_freq == rhs.FFT_freq &&
            lhs.Audio == rhs.Audio &&
            lhs.connected == rhs.connected
    }
}

class ElCidstatus: Codable, ObservableObject, Equatable {
    var distance_per_click = 100
    var relay_state = 0
    var connected = false
    
    static func == (lhs: ElCidstatus, rhs: ElCidstatus) -> Bool {
        return lhs.distance_per_click == rhs.distance_per_click &&
            lhs.relay_state == rhs.relay_state &&
            lhs.connected == rhs.connected
    }
}

class FBGStatus: Codable, ObservableObject, Equatable {
    var feet: [Float] = [255,255,255,255]
    var tank: [Float] = [255,255,255,255]
    var connected: Bool = false
    
    static func == (lhs: FBGStatus, rhs: FBGStatus) -> Bool {
        return lhs.feet == rhs.feet &&
            lhs.tank == rhs.tank &&
            lhs.connected == rhs.connected
    }
}
