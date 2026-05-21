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
    @State private var isFullScreen = false
    @StateObject var settings = SettingsHandler()
    @StateObject var robotStatus = RobotStatusObject()
    @StateObject var launchPlatformStatus = LaunchPlatformStatusObject()
    @StateObject var automationStatus = AutomationStatusObject()
    @StateObject var elCidStatus = ElCidStatusObject()
    @StateObject var digitalValveStatus = DigitalValveStatusObject()
    @StateObject var fbgStatus = FBGStatusObject()

    private let FullMinSize = CGSize(width: 2000, height: 1000)
    private let contentMinSize = CGSize(width: 1300, height: 1000)
    private let userViewContentMinSize = CGSize(width: 650, height: 1000)
    private let logger = Logger(subsystem: "CLP_Inspection_Robot_Panel", category: "App")
    
    
    
    var body: some Scene {
        WindowGroup(id: "main") {
            
            
            GeometryReader { proxy in

                let isFullScreen = proxy.size.width > FullMinSize.width && proxy.size.height > FullMinSize.height
                let smallerThenMinSize = proxy.size.width < contentMinSize.width || proxy.size.height < contentMinSize.height
                
                HStack {
                    if !smallerThenMinSize && !settings.forceUserView{
                        ContentView(disable_robot: isFullScreen)
                        if isFullScreen {
                            ControlView()
                                .clipShape(RoundedRectangle(cornerRadius: 33))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 49)
                                        .fill(.ultraThinMaterial)
                                        .stroke(.white)
                                )
                                .padding()
                        }
                    }else{
                        HStack{
                            UserView()
                            Spacer()
                            
                        }
                        
                    }
                    
                    
                    
                }
                .scrollContentBackground(.hidden)
                .bold()
                .preferredColorScheme(.dark)
                .monospacedDigit()
            }
            .background(){
                Button(""){
                    logger.info("UserView")
                    settings.forceUserView.toggle()
                }.keyboardShortcut(.return, modifiers: .command)
            }
            .background(Image("Watermark"))

            .onReceive(elCidStatus.timer) { _ in
                logger.info("elCid Fetching Status")
                elCidStatus.fetchStatus(ip: settings.ip, port: settings.port)
            }
            .onReceive(launchPlatformStatus.timer) { _ in
                logger.info("launchplatform Fetching Status")
                launchPlatformStatus.fetchStatus(ip: settings.ip, port: settings.port)
            }
            .onReceive(automationStatus.timer) { _ in
                logger.info("Auto Fetching Status")
                automationStatus.fetchStatus(ip: settings.ip, port: settings.port)
            }
            .onReceive(robotStatus.timer) { _ in
                logger.info("robot Fetching Status")
                robotStatus.fetchStatus(ip: settings.ip, port: settings.port)
            }
            .onReceive(digitalValveStatus.timer) { _ in
                logger.info("digital valve Fetching Status")
                digitalValveStatus.fetchStatus(ip: settings.ip, port: settings.port)
            }
            .onReceive(fbgStatus.timer) { _ in
                logger.info("FBG Fetching Status")
                fbgStatus.fetchStatus(ip: settings.ip, port: settings.port)
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
        .defaultSize(contentMinSize)
        
//        WindowGroup("User-View", id:"user-view") {
//            UserView()
//                .environmentObject(digitalValveStatus)
//                .environmentObject(robotStatus)
//                .environmentObject(launchPlatformStatus)
//                .environmentObject(automationStatus)
//                .environmentObject(settings)
//                .font(.title2)
//                .bold()
//        }
    }
}
