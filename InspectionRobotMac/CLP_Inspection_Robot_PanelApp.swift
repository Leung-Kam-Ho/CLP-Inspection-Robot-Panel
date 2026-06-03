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
    @StateObject private var settings = SettingsHandler()
    @StateObject private var robotStatus = RobotStatusObject()
    @StateObject private var launchPlatformStatus = LaunchPlatformStatusObject()
    @StateObject private var automationStatus = AutomationStatusObject()
    @StateObject private var elCidStatus = ElCidStatusObject()
    @StateObject private var digitalValveStatus = DigitalValveStatusObject()
    @StateObject private var fbgStatus = FBGStatusObject()

    private let fullMinSize = CGSize(width: 2000, height: 1300)
    private let contentMinSize = CGSize(width: 1300, height: 1000)
    private let userViewContentMinSize = CGSize(width: 650, height: 1000)
    private let logger = Logger(subsystem: "CLP_Inspection_Robot_Panel", category: "App")
    
    var body: some Scene {
        WindowGroup(id: "main") {
            GeometryReader { proxy in
                let enoughWidth = proxy.size.width > fullMinSize.width
                let enoughHeight = proxy.size.height > fullMinSize.height
                let isFullScreen = enoughWidth && enoughHeight
                let reachMinHeight = proxy.size.height > userViewContentMinSize.height
                
                Group {
                    if reachMinHeight{
                        UserView(showRobot: enoughHeight)
                    } else {
                        ContentView(disable_robot: isFullScreen)
                    }
                }
                .scrollContentBackground(.hidden)
                .bold()
                .preferredColorScheme(.dark)
                .monospacedDigit()
            }
            .background {
                Button("") {
                    logger.info("Toggle Force UserView")
                    settings.forceUserView.toggle()
                }
                .keyboardShortcut(.return, modifiers: .command)
            }
            .background(Image("Watermark"))
            .onAppear {
                elCidStatus.startPolling(settings: settings)
                launchPlatformStatus.startPolling(settings: settings)
                automationStatus.startPolling(settings: settings)
                robotStatus.startPolling(settings: settings)
                digitalValveStatus.startPolling(settings: settings)
//                fbgStatus.startPolling(settings: settings)
            }
            .font(.title2)
            .environmentObject(settings)
            .environmentObject(robotStatus)
            .environmentObject(launchPlatformStatus)
            .environmentObject(automationStatus)
            .environmentObject(elCidStatus)
            .environmentObject(digitalValveStatus)
            .environmentObject(fbgStatus)
        }
//        .defaultSize(contentMinSize)
    }
}
