import SwiftUI
import os

struct LaunchPlatformView: View {
    @EnvironmentObject var digitalValveStatus: DigitalValveStatusObject
    @EnvironmentObject var launchPlatformStatus: LaunchPlatformStatusObject
    @EnvironmentObject var elcidStatus: ElCidStatusObject
    @EnvironmentObject var settings: SettingsHandler
    
    @State var viewModel = ViewModel()
    
    var enabled = true
    var compact = false
    @State var show_slot = true
    var title = true
    
    let img_list = ["arrow.left.arrow.right.circle.fill", "lock.circle.fill", "popcorn.circle.fill", "lifepreserver.fill"]
    
    var body: some View {
        HStack {
            if viewModel.show {
                if !self.enabled {
                    disabledView
                } else {
                    enabledView
                }
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: viewModel.success) { old, new in
            if new {
                Logger().info("success")
                viewModel.success = false
                return true
            }
            return false
        }
        .onAppear {
            self.viewModel.previewLP_angle = Double(launchPlatformStatus.status.angle)
            self.viewModel.previewLP_angle_lastAngle = self.viewModel.previewLP_angle
            self.viewModel.show = true
        }
        .onDisappear {
            self.viewModel.show = false
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Subviews
extension LaunchPlatformView {
    
    private var launchPlatformImage: some View {
        Image("LaunchPlatform")
            .resizable()
            .padding()
//            .tint(.primary)
            .aspectRatio(contentMode: .fit)
            .rotationEffect(.degrees(Double(launchPlatformStatus.status.angle)))
            
    }
    
    private var slotOrAngleDisplay: some View {
        VStack(alignment: .center) {
            let fractionalPart: Double = enabled 
                ? Double(self.viewModel.previewLP_angle - Double(Int(self.viewModel.previewLP_angle))) 
                : Double(launchPlatformStatus.status.angle - Float(Int(launchPlatformStatus.status.angle)))
                
            let slot: Int = enabled 
                ? Int(self.viewModel.previewLP_angle / Constants.SLOT_DISTANCE_DEGREE) + 1 
                : Int(launchPlatformStatus.status.angle / Float(Constants.SLOT_DISTANCE_DEGREE)) + 1
            
            if show_slot {
                Text("Slot")
                    .foregroundStyle(Constants.offWhite)
                    .font(enabled && !compact ? .title : .caption)
                Text(String(format: "%02d", Int(slot)))
                    .tint(Constants.offWhite)
                    .contentTransition(.numericText(countsDown: true))
                    .font(.system(size: enabled && !compact ? 200 : 90))
            } else {
                Text("Angle")
                    .font(enabled && !compact ? .title : .body)
                    .foregroundStyle(Constants.offWhite)
                    
                Text(enabled ? String(format: "%03d", Int(self.viewModel.previewLP_angle)) : String(format: "%03d", Int(launchPlatformStatus.status.angle)))
                    .font(.system(size: enabled && !compact ? 180 : 70))
                    .tint(Constants.offWhite)
                    .contentTransition(.numericText(countsDown: true))
                    
                
                Text(String(format: "%02d", Int(fractionalPart * 90)))
                    .font(enabled && !compact ? .title : .body)
                    .foregroundStyle(Constants.offWhite)
                    
            }
        }
    }
    
    private var launchPlatformDragOverlay: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                let length = min(geometry.size.height, geometry.size.width)
                launchPlatformImage
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .overlay {
                        dragOverlayControls(length: length)
                    }
                    .overlay(alignment: .center) {
                        ZStack {
        //                    Image(systemName: "circle.fill")
        //                        .font(.system(size: enabled && !compact ? 400 : 150))
        //                        .foregroundStyle(.ultraThickMaterial)
                            
                            Button(action: {
                                show_slot.toggle()
                            }) {
                                slotOrAngleDisplay
                            }.buttonStyle(.plain)
                        }
                    }
                Spacer()
            }
            .scaleEffect(0.9)
        }
        .frame(maxHeight: 828.0, alignment: .center)
    }
    
    private func dragOverlayControls(length: CGFloat) -> some View {
        ZStack {
            Image("LaunchPlatform")
                .resizable()
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(0.5)
                .aspectRatio(contentMode: .fit)
            Image(systemName: "arrow.left.and.right.circle.fill")
                .offset(y: length / -2)
                .foregroundStyle(.blue)
        }
        .rotationEffect(.degrees(self.viewModel.previewLP_angle))
        .padding()
        .gesture(
            DragGesture()
                .onChanged { v in
                    var theta = (atan2(v.location.x - length / 2, length / 2 - v.location.y) - atan2(v.startLocation.x - length / 2, length / 2 - v.startLocation.y)) * 180 / .pi
                    if theta < 0 { theta += 360 }
                    let result = Double((theta + self.viewModel.previewLP_angle_lastAngle)).truncatingRemainder(dividingBy: 360)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if viewModel.locked {
                            self.viewModel.previewLP_angle = Double(self.viewModel.closestMultipleOf12(for: Int(result))) + self.viewModel.offset
                        } else {
                            self.viewModel.previewLP_angle = result + self.viewModel.offset
                        }
                        self.viewModel.previewLP_angle = self.viewModel.previewLP_angle.truncatingRemainder(dividingBy: 360)
                    }
                }
                .onEnded { _ in
                    self.viewModel.previewLP_angle_lastAngle = self.viewModel.previewLP_angle
                }
        )
    }
    
    private var disabledView: some View {
        VStack {
            Spacer()
            launchPlatformImage
                .overlay(alignment: .center) {
                    ZStack {
                        Button(action: {
                            show_slot.toggle()
                        }) {
                            slotOrAngleDisplay
                        }.buttonStyle(.plain)
                    }
                }
            Spacer()
            HStack {
                ForEach(1...4, id: \.self) { idx in
                    relayButton(for: idx)
                    if idx != 4 {
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var enabledView: some View {
        VStack {
            if title {
                Label("Launch Platform", systemImage: "chart.bar.yaxis")
                    .padding()
                    .padding(.vertical)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 33.0).fill(launchPlatformStatus.status.connected ? .orange : .red))
            }
            
            launchPlatformDragOverlay
                .frame(maxHeight: .infinity, alignment: .top)
                .background(RoundedRectangle(cornerRadius: 33).fill(.ultraThinMaterial))
                .overlay(alignment: .bottom) {
                    Text(String(format: "%05d", launchPlatformStatus.status.lazer))
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 33).fill(.red))
                        .padding()
                }
            
            controlsRow
        }
    }
    
    private var controlsRow: some View {
        HStack {
            setpointControlView
            
            if !compact {
                infoDisplayView
            }
            
            relayControlGrid
            
            if !compact {
                presetControlView
            }
        }
    }
    
    private var setpointControlView: some View {
        VStack {
            Text("Setpoint")
            Button(action: {
                LaunchPlatformStatusObject.RotatePlatform(ip: settings.ip, port: settings.port, value: .degrees(viewModel.previewLP_angle))
            }) {
                Text(String(format: "%05.1f", Float(viewModel.previewLP_angle)))
                    .padding()
                    .background(Capsule().fill(Constants.notBlack))
            }
            Button(action: {
                withAnimation {
                    viewModel.locked.toggle()
                }
            }) {
                Text(viewModel.locked ? "Slots" : "Deg")
                    .padding()
                    .background(Capsule().fill(Constants.notBlack))
            }
        }
        .lineLimit(1)
        .padding()
        .background(RoundedRectangle(cornerRadius: 33).fill(.ultraThinMaterial))
    }
    
    private var infoDisplayView: some View {
        VStack {
            Text("Info")
            let ang = launchPlatformStatus.status.angle
            let tar = launchPlatformStatus.status.setpoint
            Text("Cur :\(String(format: "%05.1f", ang))°")
                .contentTransition(.numericText(countsDown: true))
                .padding()
                .lineLimit(1)
                .background(Capsule().fill(.ultraThinMaterial))
            Text("Tar :\(String(format: "%05.1f", tar))°")
                .padding()
                .background(Capsule().fill(Constants.notBlack))
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 33).fill(.ultraThinMaterial))
    }
    
    private var relayControlGrid: some View {
        VStack {
            Text("Relay")
            HStack {
                ForEach(1...2, id: \.self) { idx in
                    relayButton(for: idx)
                }
            }
            HStack {
                ForEach(3...4, id: \.self) { idx in
                    relayButton(for: idx)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 33).fill(.ultraThinMaterial))
    }
    
    private func relayButton(for idx: Int) -> some View {
        Button(action: {
            LaunchPlatformStatusObject.setRelay(ip: settings.ip, port: settings.port, idx: Int(idx - 1))
        }) {
            let s = launchPlatformStatus.status.relay
            let index = s.index(s.startIndex, offsetBy: idx - 1)
            let state = String(launchPlatformStatus.status.relay[index])
            
            Image(systemName: img_list[idx - 1])
                .padding()
                .tint(.primary)
                .background(Circle().fill(state == "1" ? .orange : Constants.notBlack))
        }
        .keyboardShortcut(KeyEquivalent(Character("\(idx)")), modifiers: [])
    }
    
    private var presetControlView: some View {
        VStack {
            Text("Preset")
            VStack {
                presetButton(label: "-12", offset: -12.0)
                presetButton(label: "+12", offset: 12.0)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 33).fill(.ultraThinMaterial))
    }
    
    private func presetButton(label: String, offset: Double) -> some View {
        Button(action: {
            withAnimation {
                viewModel.previewLP_angle = Double(launchPlatformStatus.status.setpoint) + offset
            }
            LaunchPlatformStatusObject.RotatePlatform(ip: settings.ip, port: settings.port, value: .degrees(viewModel.previewLP_angle))
        }) {
            Text(label)
                .padding()
                .background(Capsule().fill(Constants.notBlack))
        }
    }
}

// MARK: - ViewModel & Actions
extension LaunchPlatformView {
    @Observable
    class ViewModel {
        var previewLP_angle_lastAngle = 0.0
        var previewLP_angle = 0.0
        let offset = 6.0
        var locked = false
        var show_Relay = true
        var success = false
        var show = false
        
        func closestMultipleOf12(for number: Int) -> Int {
            let remainder = number % Int(Constants.SLOT_DISTANCE_DEGREE)
            return number - remainder + (remainder > 6 ? Int(Constants.SLOT_DISTANCE_DEGREE) : 0)
        }
    }
    
    func MovePlatform(value: Int = 0) {
        // negative is backward, positive is forward, 0 is stop
    }
}

#Preview {
    @Previewable var launchPlatformStatus = LaunchPlatformStatusObject()
    @Previewable var settings = SettingsHandler()
    LaunchPlatformView()
        .environmentObject(launchPlatformStatus)
        .environmentObject(settings)
}
