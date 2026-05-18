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
            let inProgress = (autoStatus.status.mode != "Manual")
            Button(action:{
                
            }){
                Label( "\(inProgress ? "Stop" : "Start")",systemImage: inProgress ? "stop.fill" : "play.fill")
                    .padding()
                    .padding(.horizontal)
                    .tint(.primary)
                    .background(RoundedRectangle(cornerRadius: 33.0).fill(inProgress ? .red : .green))
            }
            Spacer()
            Button(action:{
                
            }){
                Label("Next", systemImage: "play.fill")
                    .padding()
                    .padding(.horizontal)
                    .tint(.primary)
                    .background(RoundedRectangle(cornerRadius: 33.0).fill(inProgress ? .gray : .orange))
            }
            .disabled(inProgress)
            Spacer()
            Text(autoStatus.status.mode)
                .lineLimit(1)
                .padding()
        }
        
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 49.0).fill(.ultraThinMaterial))
        .padding()
        
        HStack{
            VStack{
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Constants.notBlack)
//                    .padding()
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 17).fill(Constants.offWhite))
                LEDControlView()
                    .frame(maxHeight: 400)
                Spacer()
            }
            .frame(maxHeight:.infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 17.0)
                .fill(.ultraThickMaterial))
            .padding()
            .frame(width:120)
            
            VStack{
                Group{
                    launch_platform_btn
                    pressure_btn
                }
    //            .frame(maxHeight:420)
                .padding()
                InspectionSlotCardView(slot: InspectionProgressView.Inspection_Slot_Progress(slot_id: 1, EL_CID_Progress: 0, Knocker_result: 0), current_slot: true)

                autoSection
            }
        }
        .frame(width: 650)
    }
}

#Preview {
    UserView()
}
