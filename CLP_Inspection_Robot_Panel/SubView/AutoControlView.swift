//
//  AutoControlView.swift
//  CLP_Inspection_Robot_Panel
//
//  Created by Kam Ho Leung on 27/5/2025.
//

import SwiftUI
import os

struct AutoControlView: View {
    @EnvironmentObject var settings : SettingsHandler
    @EnvironmentObject var autoStatus : AutomationStatusObject
    @Binding var leftPower : Int
    @Binding var rightPower : Int
    var tight = true
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.default", category: "AutoControlView")
    
    var body: some View {
        let controlButton_L =
        Button(action:{
            switch autoStatus.autoMode {
            
            case .Standing:
                logger.info("Setting mode to Drop from Standing")
                AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: AutoMode.Drop.rawValue)
            case .Lauch:
                logger.info("Setting mode to Enter from Launch")
                AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: AutoMode.Enter.rawValue)
            case .Stairs:
                logger.info( "Setting mode to Enter_Generator from Stairs")
                AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: AutoMode.Enter_Stairs.rawValue)
            case .Baffle:
                logger.info("Setting mode to Enter_Generator from Baffle")
                AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: AutoMode.Enter_Generator.rawValue)
            default:
                let left = Int(1500 - 400 * Double(leftPower) / 100.0)
                let right = Int(1500 - 400 * Double(rightPower) / 100.0)
                logger.info("Moving robot: left=\(left), right=\(right)")
                RobotStatusObject.setServo(ip: settings.ip, port: settings.port, servo: [left,right,left,right])
            }
            
            
        }){
            Image(systemName: "arrowtriangle.up.fill")
                .padding()
                .tint(.primary)
                .background(Capsule()
                    .fill(Constants.notBlack))
        }.keyboardShortcut(.upArrow, modifiers: [])
        
        let controlButton_S =
        Button(action:{
            if autoStatus.autoMode == .Manual {
                logger.info("Stopping robot in Manual mode")
                RobotStatusObject.setServo(ip: settings.ip, port: settings.port, servo: [1500,1500,1500,1500])
            }
            logger.info("Setting mode to Manual")
            AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: AutoMode.Manual.rawValue)
        }){
            Image(systemName: "stop.fill")
                .padding()
                .tint(.primary)
                .background(Capsule()
                    .fill(Constants.notBlack))
        }.keyboardShortcut(.space, modifiers: [])
        
        let controlButton_R =
        Button(action:{
            switch autoStatus.autoMode {
            
            case .Standing:
                logger.info("Setting mode to Elevate from Standing")
                AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: AutoMode.Elevate.rawValue)
            case .Lauch:
                logger.info("Setting mode to Exit from Launch")
                AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: AutoMode.Exit.rawValue)
            case .Stairs:
                logger.info( "Setting mode to Exit_Generator from Stairs")
                AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: AutoMode.Exit_Stairs.rawValue)
            case .Baffle:
                logger.info("Setting mode to Exit_Generator from Baffle")
                AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: AutoMode.Exit_Generator.rawValue)
            default:
                let left = Int(1500 + 400 * Double(leftPower) / 100.0)
                let right = Int(1500 + 400 * Double(rightPower) / 100.0)
                logger.info("Moving robot backwards: left=\(left), right=\(right)")
                RobotStatusObject.setServo(ip: settings.ip, port: settings.port, servo: [left,right,left,right])
            }
            
        }){
            Image(systemName: "arrowtriangle.down.fill")
                .padding()
                .tint(.primary)
                .background(Capsule()
                    .fill(Constants.notBlack))
            
        }.keyboardShortcut(.downArrow, modifiers: [])
        
        VStack{
            controlButton_L
            controlButton_S
            controlButton_R
        }.padding()
            .background(Capsule()
                .fill(.ultraThinMaterial))
    }
}

//#Preview {
//    @Previewable var settings = SettingsHandler()
//    @Previewable var autoStatus = AutomationStatusObject()
//    AutoControlView()
//        .environmentObject(settings)
//        .environmentObject(autoStatus)
//}
