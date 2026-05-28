import SwiftUI
import os

struct LaunchPlatformView: View {
    @EnvironmentObject var digitalValveStatus: DigitalValveStatusObject
    @EnvironmentObject var launchPlatformStatus: LaunchPlatformStatusObject
    @EnvironmentObject var elcidStatus: ElCidStatusObject
    @EnvironmentObject var settings: SettingsHandler
    
    @State private var viewModel = ViewModel()
    @State private var showSlot: Bool
    
    let enabled: Bool
    let compact: Bool
    let title: Bool
    
    private let imgList = [
        "arrow.left.arrow.right.circle.fill",
        "lock.open.rotation",
        "brakesignal.dashed",
        "lifepreserver.fill"
    ]
    
    init(enabled: Bool = true, compact: Bool = false, showSlot: Bool = true, title: Bool = true) {
        self.enabled = enabled
        self.compact = compact
        self._showSlot = State(initialValue: showSlot)
        self.title = title
    }
    
    var body: some View {
        HStack {
            if viewModel.show {
                if !enabled {
                    disabledView
                } else {
                    enabledView
                }
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: viewModel.success) { _, new in
            if new {
                Logger().info("success")
                viewModel.success = false
                return true
            }
            return false
        }
        .onAppear {
            viewModel.previewLP_angle = Double(launchPlatformStatus.status.angle)
            viewModel.previewLP_angle_lastAngle = viewModel.previewLP_angle
            viewModel.show = true
        }
        .onDisappear {
            viewModel.show = false
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Subviews & Layout Helpers
extension LaunchPlatformView {
    
    private var currentAngle: Double {
        enabled ? viewModel.previewLP_angle : Double(launchPlatformStatus.status.angle)
    }
    
    private var currentSlot: Int {
        Int(currentAngle / Constants.SLOT_DISTANCE_DEGREE) + 1
    }
    
    private var fractionalPart: Double {
        currentAngle.truncatingRemainder(dividingBy: 1.0)
    }
    
    private var launchPlatformImage: some View {
        Image("LaunchPlatform")
            .resizable()
            .padding()
            .aspectRatio(contentMode: .fit)
            .rotationEffect(.degrees(Double(launchPlatformStatus.status.angle)))
    }
    
    private var slotOrAngleDisplay: some View {
        VStack(alignment: .center) {
            if showSlot {
                Text("Slot")
                    .foregroundStyle(Constants.offWhite)
                    .font(enabled && !compact ? .title : .caption)
                Text(String(format: "%02d", currentSlot))
                    .tint(Constants.offWhite)
                    .contentTransition(.numericText(countsDown: true))
                    .font(.system(size: enabled && !compact ? 200 : 90))
            } else {
                Text("Angle")
                    .font(enabled && !compact ? .title : .body)
                    .foregroundStyle(Constants.offWhite)
                    
                Text(String(format: "%03d", Int(currentAngle)))
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
                        Button(action: {
                            showSlot.toggle()
                        }) {
                            slotOrAngleDisplay
                        }
                        .buttonStyle(.plain)
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
        .rotationEffect(.degrees(viewModel.previewLP_angle))
        .padding()
        .gesture(
            DragGesture()
                .onChanged { value in
                    handleDragGestureChange(value, length: length)
                }
                .onEnded { _ in
                    viewModel.previewLP_angle_lastAngle = viewModel.previewLP_angle
                }
        )
    }
    
    private func handleDragGestureChange(_ value: DragGesture.Value, length: CGFloat) {
        let centerX = length / 2
        let centerY = length / 2
        
        let startAngle = atan2(value.startLocation.x - centerX, centerY - value.startLocation.y)
        let currentDragAngle = atan2(value.location.x - centerX, centerY - value.location.y)
        
        var angleDifference = (currentDragAngle - startAngle) * 180 / .pi
        if angleDifference < 0 {
            angleDifference += 360
        }
        
        let result = (angleDifference + viewModel.previewLP_angle_lastAngle).truncatingRemainder(dividingBy: 360)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if viewModel.locked {
                viewModel.previewLP_angle = Double(viewModel.closestMultipleOf12(for: Int(result))) + viewModel.offset
            } else {
                viewModel.previewLP_angle = result + viewModel.offset
            }
            viewModel.previewLP_angle = viewModel.previewLP_angle.truncatingRemainder(dividingBy: 360)
        }
    }
    
    private var disabledView: some View {
        VStack {
            Spacer()
            launchPlatformImage
                .overlay(alignment: .center) {
                    Button(action: {
                        showSlot.toggle()
                    }) {
                        slotOrAngleDisplay
                    }
                    .buttonStyle(.plain)
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
    
    private func isRelayActive(at index: Int) -> Bool {
        let relayString = launchPlatformStatus.status.relay
        guard relayString.indices.contains(relayString.index(relayString.startIndex, offsetBy: index)) else {
            return false
        }
        let charIndex = relayString.index(relayString.startIndex, offsetBy: index)
        return relayString[charIndex] == "1"
    }
    
    private func relayButton(for idx: Int) -> some View {
        Button(action: {
            LaunchPlatformStatusObject.setRelay(ip: settings.ip, port: settings.port, idx: idx - 1)
        }) {
            let isActive = isRelayActive(at: idx - 1)
            Image(systemName: imgList[idx - 1])
                .padding()
                .tint(.primary)
                .background(Circle().fill(isActive ? .orange : Constants.notBlack))
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
    
    func movePlatform(value: Int = 0) {
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
