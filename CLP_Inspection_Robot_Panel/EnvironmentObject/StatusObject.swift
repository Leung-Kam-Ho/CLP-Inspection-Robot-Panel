//swift
//  CLP_Inspection_Robot_Panel
//
//  Created by Kam Ho Leung on 26/5/2025.
//

import Foundation
import SwiftUI
import os
import Combine

// Protocol to standardise connection state checking
protocol ConnectableStatus {
    var connected: Bool { get set }
}

extension RobotStatus: ConnectableStatus {}
extension DigitalValve_Status: ConnectableStatus {}
extension LaunchPlatformStatus: ConnectableStatus {}
extension AutomationStatus: ConnectableStatus {}
extension ElCidstatus: ConnectableStatus {}
extension FBGStatus: ConnectableStatus {}

enum AutoMode_segment: String, CaseIterable {
    case Manual, Standing, Lauch, Stairs, Baffle, Testing
}

private let baseLogger = Logger(subsystem: "CLP_Inspection_Robot_Panel", category: "NetworkCommand")

// Base class for status objects to avoid code duplication
class BaseStatusObject<T: Decodable & Equatable>: ObservableObject {
    @Published var status: T
    private let initialStatus: T
    private let networkManager = NetworkManager.shared
    private let statusRoute: String
    private let logger: Logger
    
    private var timerSubscription: AnyCancellable?
    
    init(initialStatus: T, statusRoute: String) {
        self.initialStatus = initialStatus
        self.status = initialStatus
        self.statusRoute = statusRoute
        self.logger = Logger(subsystem: "CLP_Inspection_Robot_Panel", category: String(describing: T.self))
    }
    
    func startPolling(settings: SettingsHandler, interval: TimeInterval = Constants.MEDIUM_RATE) {
        stopPolling()
        
        // Fetch once immediately when polling starts
        fetchStatus(ip: settings.ip, port: settings.port)
        
        timerSubscription = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self, weak settings] _ in
                guard let self = self, let settings = settings else { return }
                self.fetchStatus(ip: settings.ip, port: settings.port)
            }
    }
    
    func stopPolling() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
    
    func fetchStatus(ip: String, port: Int) {
        NetworkManager.getRequest(ip: ip, port: port, route: statusRoute) { [weak self] (result: Result<T, Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let newStatus):
                DispatchQueue.main.async {
                    if self.status != newStatus {
                        self.logger.info("Status updated for \(self.statusRoute)")
                        withAnimation(.easeInOut) {
                            self.status = newStatus
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.logger.error("Failed to fetch \(self.statusRoute): \(error.localizedDescription)")
                    
                    // Retain last-known data, but set connected to false to prevent UI flickering
                    if var connectable = self.status as? ConnectableStatus {
                        if connectable.connected {
                            self.objectWillChange.send()
                            connectable.connected = false
                        }
                    } else {
                        self.status = self.initialStatus
                    }
                }
            }
        }
    }
    
    static func sendCommand<V: Encodable>(ip: String, port: Int, route: String, data: V) {
        NetworkManager.postRequest(ip: ip, port: port, route: route, value: data) { success in
            DispatchQueue.main.async {
                if success {
                    baseLogger.info("POST request succeeded for \(route)")
                } else {
                    baseLogger.error("POST request failed for \(route)")
                }
            }
        }
    }
}

// Robot status object
class RobotStatusObject: BaseStatusObject<RobotStatus> {
    struct setServoCommand: Encodable {
        var servo: [Int]
    }
    struct setRelayCommand: Encodable {
        var relay: Int
    }
    struct setLEDBrightness : Encodable{
        var brightness: Float
    }
    init() {
        super.init(initialStatus: RobotStatus(), statusRoute: "/robot_status")
    }
    static func setServo(ip: String, port: Int, servo: [Int]) {
        let command = setServoCommand(servo: servo)
        
        sendCommand(ip: ip, port: port, route: "/robot/servo", data: command)
    }
    
    static func setRelay(ip: String, port: Int, relay: Int) {
        
        let command = setRelayCommand(relay: relay)
        
        sendCommand(ip: ip, port: port, route: "/robot/relay", data: command)
    }
    static func setLED(ip: String, port: Int, brightness: Float) {
        let command = setLEDBrightness(brightness: brightness)
        sendCommand(ip: ip, port: port, route: "/robot/led", data: command)
        Logger().info("set \(brightness)")
    }

}

// Launch platform status object
class LaunchPlatformStatusObject: BaseStatusObject<LaunchPlatformStatus> {
    struct setAngleCommand : Encodable {
        var angle : Float
    }
    struct setRelayCommand: Encodable {
        var idx : Int
    }
    init() {
        super.init(initialStatus: LaunchPlatformStatus(), statusRoute: "/launch_platform_status")
    }
    static func setRelay(ip: String, port: Int, idx: Int) {
        let command = setRelayCommand(idx: idx)
        sendCommand(ip: ip, port: port, route: "/launch_platform/relay", data: command)
    }
    static func RotatePlatform(ip: String, port: Int, value : Angle = .degrees(0)){
        let angle = value.degrees < 0 ? 360 + value.degrees : value.degrees
        Logger().info("set \(angle)")
        sendCommand(ip: ip, port: port, route: "/launch_platform/angle", data: setAngleCommand(angle: Float(angle)))
    }
}

// Automation status object
class AutomationStatusObject: BaseStatusObject<AutomationStatus> {
    struct setModeCommand : Encodable {
        var mode : String
    }
    var autoMode: AutoMode_segment = .Manual
    var autoModeDetail: AutoMode = .Enter
    init() {
        super.init(initialStatus: AutomationStatus(), statusRoute: "/auto_status")
    }
    static func setMode(ip: String, port: Int, mode: String) {
        let command = setModeCommand(mode: mode)
        sendCommand(ip: ip, port: port, route: "/auto", data: command)
    }
}



// ElCid status object
class ElCidStatusObject: BaseStatusObject<ElCidstatus> {
    struct setRelayCommand: Encodable {
        var state : Bool
    }
    init() {
        super.init(initialStatus: ElCidstatus(), statusRoute: "/el_cid_status")
    }
    
    static func setRelay(ip: String, port: Int, state: Bool) {
        let command = setRelayCommand(state: state)
        sendCommand(ip: ip, port: port, route: "/EL_CID", data: command)
    }
}

// Digital valve status object
class DigitalValveStatusObject: BaseStatusObject<DigitalValve_Status> {
    struct setPressureCommand: Encodable {
        var channel: Int
        var pressure: Double
    }
    init() {
        super.init(initialStatus: DigitalValve_Status(), statusRoute: "/digital_valve_status")
    }
    
    static func setPressure(ip: String, port: Int, channel: Int, pressure: Double) {
        let command = setPressureCommand(channel : channel,pressure: pressure)
        
        sendCommand(ip: ip, port: port, route: "/robot/pressure", data: command)
    }
}


// Robot status object
class FBGStatusObject: BaseStatusObject<FBGStatus> {
    struct setTargetCommand: Encodable {
        var channel: String
        var value: Int
    }
    init() {
        super.init(initialStatus: FBGStatus(), statusRoute: "/fbg_status")
    }
    static func setTarget(ip: String, port: Int, channel: String, value: Int) {
        let command = setTargetCommand(channel : channel,value: value)
        
        sendCommand(ip: ip, port: port, route: "/fbg_target", data: command)
    }
    static func resetTarget(ip: String, port: Int, channel: String, value: Int) {
        let command = setTargetCommand(channel : channel,value: value)
        
        sendCommand(ip: ip, port: port, route: "/fbg_target_reset", data: command)
    }

}


// progress status object
class ProgressStatusObject: BaseStatusObject<ProgressStatus> {
    init() {
        super.init(initialStatus: ProgressStatus(), statusRoute: "/progress_status")
    }
}