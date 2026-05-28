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

        let current_slot = Int(launchPlatformStatus.status.angle / Float(Constants.SLOT_DISTANCE_DEGREE))
        let slot_aligned = current_slot == selected_slot

        let robot_btn =
        Button(action:{
        }){
            GroupBox("Control"){
                VStack{
                    GridRelayView(pressure_view : false)
                }
                
            }
            
            
            .clipShape(.rect(cornerRadius: 33))
            .overlay(alignment: .topTrailing, content: {
                if robotStatus.status.connected{
                    Text("●")
                        .foregroundStyle(.green)
                        .font(.caption)
                        .padding()
                }
//                    .padding()
            })
            
            .padding()
            
                .background(RoundedRectangle(cornerRadius: 49.0)
//                    .stroke(robotStatus.status.connected ? .green : .gray,lineWidth: 3)
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
            .overlay(alignment: .topTrailing, content: {
                if launchPlatformStatus.status.connected{
                    Text("●")
                        .foregroundStyle(.orange)
                        .font(.caption)
                        .padding()
                }
            })
            
            .clipShape(.rect(cornerRadius: 33))
            .padding()
            .background(RoundedRectangle(cornerRadius: 49.0)
//                .stroke(launchPlatformStatus.status.connected ? .orange : .gray, lineWidth: 3)
                .fill(.ultraThinMaterial))
            
            
        }
        .buttonStyle(.plain).opacity(launchPlatformStatus.status.connected ? 1 : 0.5)
        
        let autoSection =
        HStack {
            let inProgress = (autoStatus.status.mode != "Manual")
            Button(action:{
                let slot_angle = (Double(selected_slot) * 12.0) + 6
                LaunchPlatformStatusObject.RotatePlatform(ip: settings.ip, port: settings.port, value: .degrees(slot_angle))
                
            }){
                    
                    HStack{
                        Text("Go To Slot")
                        Image(systemName: "\(selected_slot+1).circle.fill")
                    }
                    .padding(10)
                    .padding(.horizontal)
                    .tint(.primary)
                    .background(RoundedRectangle(cornerRadius: 17.0).fill(inProgress ? .gray : .orange))
            }
            .disabled(inProgress)
            Spacer()
            Button(action:{
                if !inProgress{
                    AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: autoStatus.autoModeDetail.rawValue)
                }else{
                    AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: AutoMode.Manual.rawValue)
                }
            }){
                Label( "\(inProgress ? "Stop" : "\(autoStatus.autoModeDetail.rawValue)")",systemImage: inProgress ? "stop.fill" : "play.fill")
                    .padding(10)
                    .padding(.horizontal)
                    .tint(.primary)
                    .background(RoundedRectangle(cornerRadius: 17.0).fill(inProgress ? .red : slot_aligned ? .green : .gray))
            }
            .contextMenu {
                Section {
                    ForEach(AutoMode.allCases, id: \.self) { mode in
                        let name = mode.rawValue
                        if mode != .Manual && mode != .Testing{
                            Button(action: {
                                switch mode {
                                case .Manual, .Testing:
                                    AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: name)
                                default:
                                    autoStatus.autoModeDetail = mode
                                }
                                autoStatus.autoModeDetail = mode
                            }, label: {
                                Text(name)
                                    .font(.title)
                                    .padding()
                            })
                        }
                        
                    }
                }
            }
            .disabled(!slot_aligned)
//            Spacer()
            
//            Spacer()
//            Text(autoStatus.status.mode)
//                .lineLimit(1)
//                .padding()
        }
        .font(.title2)
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
                    AutoStageView()
                }
                .frame(maxHeight:.infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 33.0)
                    .fill(.ultraThickMaterial))
                .padding()
                .frame(width:120)
                
                VStack{
                    launch_platform_btn

                    .padding()
                    robot_btn
                        .padding()
                    
                    // tab view for inspection progress, total 30 slots, each slot has its own progress view, and can be selected to show more details
                    TabView(selection: $selected_slot){
                        ForEach(0..<30) { index in
                            let slot = InspectionProgressView.Inspection_Slot_Progress(slot_id: index + 1, EL_CID_Progress: 0.0, Knocker_result: 0.0)
                            InspectionSlotCardView(slot: slot, current_slot: index == current_slot)
                        }
                    }
                    .tabViewStyle(.page)
                    autoSection
                }
            }
            .frame(width: 650)

            ContentView()
                .frame(minWidth:1000)
//                .tabViewStyle(.page)
        }
    }
}

#Preview {
    UserView()
}
