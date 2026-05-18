//
//  UserView.swift
//  CLP_Inspection_Robot_Panel
//
//  Created by KamHo on 18/5/26.
//

import SwiftUI

struct UserView: View {
    @EnvironmentObject var robotStatus: RobotStatusObject
    @EnvironmentObject var launchPlatformStatus : LaunchPlatformStatusObject
    @EnvironmentObject var autoStatus: AutomationStatusObject
    @EnvironmentObject var settings : SettingsHandler
    
    var body: some View {
        let pressure_btn =
        Button(action:{
        }){
            GroupBox("Control"){
                VStack{
                    GridRelayView()
                        
                }
            }
            .clipShape(.rect(cornerRadius: 33))
            .padding()
                .background(RoundedRectangle(cornerRadius: 49.0)
                    .fill(.ultraThinMaterial))
        }
        .buttonStyle(.plain)
        .opacity(robotStatus.status.connected ? 1 : 0.5)
        let launch_platform_btn =
        Button(action:{
            
        }){
            GroupBox("LaunchPlatform"){
                VStack{
                    LaunchPlatformView(enabled : false)
                    
                }
            }
            .clipShape(.rect(cornerRadius: 33))
            .padding()
                .background(RoundedRectangle(cornerRadius: 49.0)
                    .fill(.ultraThinMaterial))
            
            
        }.buttonStyle(.plain).opacity(launchPlatformStatus.status.connected ? 1 : 0.5)
        let autoSection =
        HStack {
            Button(action:{
                
            }){
                let inProgress = (autoStatus.status.mode != "Manual")
                Label( "\(inProgress ? "Stop" : "Start")",systemImage: inProgress ? "stop.fill" : "play.fill")
                    .padding()
                    .padding(.horizontal)
                    .tint(.primary)
                    .background(RoundedRectangle(cornerRadius: 33.0).fill(inProgress ? .red : .green))
            }
            
            Spacer()
            
            Text(autoStatus.status.mode)
                .lineLimit(1)
                .font(.title)
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 49.0).fill(.ultraThickMaterial))
        .padding()
        
        VStack{
            TabView(content: {
                launch_platform_btn
                pressure_btn
            })
            .padding()
            
            
            autoSection
            
        }
        .frame(width: 500)
    }
}

#Preview {
    UserView()
}
