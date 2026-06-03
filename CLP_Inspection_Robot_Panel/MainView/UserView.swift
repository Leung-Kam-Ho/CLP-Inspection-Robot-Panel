//
//  UserView.swift
//  CLP_Inspection_Robot_Panel
//
//  Created by KamHo on 18/5/26.
//

import SwiftUI

struct UserView: View {
    @EnvironmentObject private var robotStatus: RobotStatusObject
    @EnvironmentObject private var launchPlatformStatus: LaunchPlatformStatusObject
    @EnvironmentObject private var autoStatus: AutomationStatusObject
    @EnvironmentObject private var settings: SettingsHandler
    @EnvironmentObject private var progressStatus: ProgressStatusObject
    
    @State private var selectedSlot: Int = 0
    
    let showRobot : Bool
    
    init(showRobot: Bool = true){
        self.showRobot = showRobot
    }
    
    // MARK: - Computed Properties
    
    private var currentSlot: Int {
        Int(Float(robotStatus.status.roll_angle) / Float(Constants.SLOT_DISTANCE_DEGREE))
    }
    
    private var isSlotAligned: Bool {
        // current slot = selectedSlot and the angle of launchplatform is +- 1 of the setpoint
        let launchPlatformAngle = launchPlatformStatus.status.angle.truncatingRemainder(dividingBy: 360)
        let launchPlatformSetpoint = launchPlatformStatus.status.setpoint.truncatingRemainder(dividingBy: 360)
        return (currentSlot == selectedSlot) && (abs(launchPlatformAngle - launchPlatformSetpoint) <= 0.5)
    }
    
    private var isAutomationInProgress: Bool {
        autoStatus.status.mode != "Manual"
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            HStack {
                sidebarControlView
                
                VStack {
                    launchPlatformButton
                        .padding()
                    
                    if showRobot{
                        robotButton
                            .padding()
                    }
                    
                    // Tab view for inspection progress.
                    // Total 30 slots; each slot has its own progress view and can be selected to show more details.
                    TabView(selection: $selectedSlot) {
                        ForEach(0..<30) { index in
                            let slot = InspectionProgressView.Inspection_Slot_Progress(
                                slot_id: index + 1,
                                EL_CID_Progress: progressStatus.status.elcid_progress[index],
                                Knocker_result: 0.0
                            )
                            InspectionSlotCardView(slot: slot, current_slot: index == currentSlot && isSlotAligned)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page)
                    
                    automationSection
                }
            }
            .frame(width: 650)
            
            ContentView()
                .frame(minWidth: 1000)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var sidebarControlView: some View {
        VStack {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Constants.notBlack)
                .padding()
                .background(RoundedRectangle(cornerRadius: 17).fill(Constants.offWhite))
            
            LEDControlView()
                .frame(maxHeight: 400)
            
            Spacer()
            
            AutoStageView()
        }
        .frame(maxHeight: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 33.0).fill(.ultraThickMaterial))
        .padding()
        .frame(width: 120)
    }
    
    @ViewBuilder
    private var robotButton: some View {
        Button(action: {}) {
            GroupBox("Control") {
                VStack {
                    GridRelayView(pressure_view: false)
                }
            }
            .clipShape(.rect(cornerRadius: 33))
            .overlay(alignment: .topTrailing) {
                if robotStatus.status.connected {
                    Text("●")
                        .foregroundStyle(.green)
                        .font(.caption)
                        .padding()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 49.0)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
        .opacity(robotStatus.status.connected ? 1.0 : 0.5)
    }
    
    @ViewBuilder
    private var launchPlatformButton: some View {
        Button(action: {}) {
            GroupBox("LaunchPlatform") {
                VStack {
                    LaunchPlatformView(enabled: false)
                }
            }
            .overlay(alignment: .topTrailing) {
                if launchPlatformStatus.status.connected {
                    Text("●")
                        .foregroundStyle(.orange)
                        .font(.caption)
                        .padding()
                }
            }
            .clipShape(.rect(cornerRadius: 33))
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 49.0)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.plain)
        .opacity(launchPlatformStatus.status.connected ? 1.0 : 0.5)
    }
    
    @ViewBuilder
    private var automationSection: some View {
        HStack {
            Button(action: {
                let slotAngle = (Double(selectedSlot) * 12.0) + 6
                LaunchPlatformStatusObject.RotatePlatform(
                    ip: settings.ip,
                    port: settings.port,
                    value: .degrees(slotAngle)
                )
            }) {
                HStack {
                    Text("Go To Slot")
                    Image(systemName: "\(selectedSlot + 1).circle.fill")
                }
                .padding(10)
                .padding(.horizontal)
                .tint(.primary)
                .background(
                    RoundedRectangle(cornerRadius: 17.0)
                        .fill(isAutomationInProgress ? .gray : .orange)
                )
            }
            .disabled(isAutomationInProgress)
            
            Spacer()
            
            Button(action: {
                if !isAutomationInProgress {
                    AutomationStatusObject.setMode(
                        ip: settings.ip,
                        port: settings.port,
                        mode: autoStatus.autoModeDetail.rawValue
                    )
                } else {
                    AutomationStatusObject.setMode(
                        ip: settings.ip,
                        port: settings.port,
                        mode: AutoMode.Manual.rawValue
                    )
                }
            }) {
                Label(
                    isAutomationInProgress ? "Emergancy Stop" : "\(autoStatus.autoModeDetail.rawValue)",
                    systemImage: isAutomationInProgress ? "stop.fill" : "play.fill"
                )
                .padding(10)
                .padding(.horizontal)
                .tint(.primary)
                .background(
                    RoundedRectangle(cornerRadius: 17.0)
                        .fill(isAutomationInProgress ? .red : isSlotAligned ? .green : .gray)
                )
            }
            .contextMenu {
                Section {
                    ForEach(AutoMode.allCases, id: \.self) { mode in
                        if mode != .Manual && mode != .Testing {
                            Button(action: {
                                autoStatus.autoModeDetail = mode
                            }) {
                                Text(mode.rawValue)
                                    .font(.title)
                                    .padding()
                            }
                        }
                    }
                }
            }
            .disabled(!isSlotAligned && !isAutomationInProgress)
        }
        .font(.title2)
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 33.0)
                .fill(.ultraThinMaterial)
                .stroke(.white, lineWidth: 2)
        )
        .padding()
    }
}

#Preview {
    UserView()
}
