import SwiftUI
import os

struct ContentView: View {
    @EnvironmentObject var robotStatus: RobotStatusObject
    @EnvironmentObject var digitalValveStatus: DigitalValveStatusObject
    @EnvironmentObject var launchPlatformStatus: LaunchPlatformStatusObject
    @EnvironmentObject var autoStatus: AutomationStatusObject
    @EnvironmentObject var elcidStatus: ElCidStatusObject
    @EnvironmentObject var settings: SettingsHandler
    
    @State var viewModel = ViewModel()
    var disable_robot = false
    @AppStorage("MyAppTabViewCustomization") private var customization: TabViewCustomization
    
    var body: some View {
        GeometryReader { screen in
            let bigEnough = UIScreen.main.traitCollection.userInterfaceIdiom == .pad
            
            HStack {
                TabView(selection: self.$viewModel.selectedTab) {
                    if bigEnough {
                        Tab("All", systemImage: "widget.small", value: Tabs.All) {
                            ConceptView(selection: self.$viewModel.selectedTab)
                        }
                    }
                    
                    Tab("Auto", systemImage: "point.topright.filled.arrow.triangle.backward.to.point.bottomleft.scurvepath", value: Tabs.Auto) {
                        autoView
                    }
                    
//                    Tab("Camera", systemImage: "camera.fill", value: Tabs.Camera) {
//                        cameraView
//                    }
                    if !disable_robot{
                        Tab("Robot", systemImage: "macstudio.fill", value: Tabs.Robot) {
                            controlView(compact: !bigEnough)
                        }
                    }
                    
                    
                    Tab("Launch Platform", systemImage: "circle.bottomrighthalf.pattern.checkered", value: Tabs.LaunchPlatform) {
                        launchPlatformView(compact: !bigEnough)
                    }
                    
                    Tab("Pressure", systemImage: "chart.bar.fill", value: Tabs.Pressure) {
                        pressureView
                    }
                    
                    
                    Tab("ToF", systemImage: "pencil.and.ruler", value: Tabs.ToF) {
                        ToFView()
                            .padding()
                    }
                    
                    Tab("LED", systemImage: "flashlight.off.fill", value: Tabs.LED) {
                        ledView
                    }
                }
                .tabViewStyle(.page)
            }
        }
    }
}

// MARK: - Subviews
extension ContentView {
    private var cameraView: some View {
        Camera_WebView()
            .padding()
            .background(RoundedRectangle(cornerRadius: 49).fill(.ultraThinMaterial).stroke(.white))
            .padding()
    }
    
    private func controlView(compact: Bool) -> some View {
        ControlView(compact: compact)
            .padding()
            .background(RoundedRectangle(cornerRadius: 49).fill(.ultraThinMaterial).stroke(.white))
            .padding()
    }
    
    private var autoView: some View {
        AutoView()
            .padding()
            .background(RoundedRectangle(cornerRadius: 49.0).fill(.ultraThinMaterial).stroke(.white))
            .padding()
    }
    
    private func launchPlatformView(compact: Bool) -> some View {
        LaunchPlatformView(compact: compact, show_slot: false)
            .padding()
            .background(RoundedRectangle(cornerRadius: 49.0).fill(.ultraThinMaterial).stroke(.white))
            .padding()
    }
    
    private var pressureView: some View {
        VStack {
            Label("Pressure CTRL", systemImage: "chart.bar.yaxis")
                .padding()
                .padding(.vertical)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 33.0).fill(digitalValveStatus.status.connected ? .green : .red))
            
            PressureView(enabled: true)
                .padding()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 49.0).fill(.ultraThinMaterial).stroke(.white))
        .padding()
    }
    
    private var ledView: some View {
        LEDControlView()
            .padding()
            .background(RoundedRectangle(cornerRadius: 49.0).fill(.ultraThinMaterial).stroke(.white))
            .padding()
    }
}

// MARK: - Types
extension ContentView {
    enum Tabs: Hashable {
        case All
        case Auto
        case Robot
        case Pressure
        case LaunchPlatform
        case ToF
        case Camera
        case Camera_full
        case Progress
        case LED
        case placeHolder
    }
    
    enum CameraMode: String, CaseIterable {
        case half = "inset.filled.lefthalf.righthalf.rectangle"
        case none = "inset.filled.topleft.topright.bottomleft.bottomright.rectangle"
    }
    
    @Observable
    class ViewModel {
        var selectedTab: Tabs = .All
        var camera_tab_toggle = false
        var cameraMode: CameraMode = .none
    }
}
