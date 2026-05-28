//
//  CLP_Inspection_Robot_PanelApp.swift
//  CLP_Inspection_Robot_Panel
//
//  Created by Kam Ho Leung on 14/7/2024.
//

import SwiftUI
import os

@main
struct CLP_Inspection_Robot_PanelApp: App {

    @StateObject var settings = SettingsHandler()
    @StateObject var robotStatus = RobotStatusObject()
    @StateObject var launchPlatformStatus = LaunchPlatformStatusObject()
    @StateObject var automationStatus = AutomationStatusObject()
    @StateObject var elCidStatus = ElCidStatusObject()
    @StateObject var digitalValveStatus = DigitalValveStatusObject()
    @StateObject var fbgStatus = FBGStatusObject()
    var body: some Scene {
        WindowGroup {
            HStack {
                ContentView()
//                Spacer()
//                AutoView()
            }
            .background(Image("Watermark"))
            .onAppear {
                elCidStatus.startPolling(settings: settings)
                launchPlatformStatus.startPolling(settings: settings)
                automationStatus.startPolling(settings: settings)
                robotStatus.startPolling(settings: settings)
                digitalValveStatus.startPolling(settings: settings)
                fbgStatus.startPolling(settings: settings)
            }
            .font(.title2)
//            .environmentObject(station)
            .environmentObject(settings)
            .environmentObject(robotStatus)
            .environmentObject(launchPlatformStatus)
            .environmentObject(automationStatus)
            .environmentObject(elCidStatus)
            .environmentObject(digitalValveStatus)
            .environmentObject(fbgStatus)
            
            .scrollContentBackground(.hidden)
            .bold()
            .preferredColorScheme(.dark)

            .monospacedDigit()
        }
    }
}
