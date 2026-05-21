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
    
    @State var selected_slot : Int = 0
    var body: some View {
        let auto_btn =
        AutoView()
            .padding()
            .background(RoundedRectangle(cornerRadius: 49.0)
                .fill(.ultraThinMaterial)
                .stroke(.white)
            )
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
                    .background(RoundedRectangle(cornerRadius: 17.0).fill(inProgress ? .red : .green))
            }
            Spacer()
            Button(action:{
                let slot_angle = (Double(selected_slot) * 12.0) + 6
                LaunchPlatformStatusObject.RotatePlatform(ip: settings.ip, port: settings.port, value: .degrees(slot_angle))
                
            }){
                    HStack{
                        Text("Go To Slot")
                        Image(systemName: "\(selected_slot+1).circle.fill")
                    }
                    .padding()
                    .padding(.horizontal)
                    .tint(.primary)
                    .background(RoundedRectangle(cornerRadius: 17.0).fill(inProgress ? .gray : .orange))
            }
            .disabled(inProgress)
//            Spacer()
//            Text(autoStatus.status.mode)
//                .lineLimit(1)
//                .padding()
        }
        
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 33.0).fill(.ultraThinMaterial).stroke(.white, lineWidth: 2))
        .padding()
        
        HStack{
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
                    AutoStageView(totaleStage: 6, currentStage: 1)
                }
                .frame(maxHeight:.infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 17.0)
                    .fill(.ultraThickMaterial))
                .padding()
                .frame(width:120)
                
                VStack{
                    TabView{
                        launch_platform_btn
                        pressure_btn
                        auto_btn
                    }
                    .frame(height: 450)
                    .tabViewStyle(.page)
                    .padding()
                    
                    // tab view for inspection progress, total 30 slots, each slot has its own progress view, and can be selected to show more details
                    TabView(selection: $selected_slot){
                        ForEach(0..<30) { index in
                            let slot = InspectionProgressView.Inspection_Slot_Progress(slot_id: index + 1, EL_CID_Progress: 0.0, Knocker_result: 0.0)
                            InspectionSlotCardView(slot: slot, current_slot: index + 1 == selected_slot)
                        }
                    }
                    .tabViewStyle(.page)
                    autoSection
                }
            }
            .frame(width: 650)
            Color.clear
                .background(RoundedRectangle(cornerRadius: 33.0)
                    .fill(.ultraThickMaterial))
                .padding()
                .background(RoundedRectangle(cornerRadius: 49.0)
                    .fill(.ultraThinMaterial))
                .padding()
        }
    }
}

#Preview {
    UserView()
}
