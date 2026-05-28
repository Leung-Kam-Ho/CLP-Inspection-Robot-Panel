import SwiftUI
import os

// MARK: - AutoMenu
struct AutoMenu<Content: View>: View {
    @EnvironmentObject var autoStatus: AutomationStatusObject
    @EnvironmentObject var settings: SettingsHandler
    
    let content: Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Menu {
            let inProgress = (autoStatus.status.mode != "Manual")
            
            Section {
                ForEach(AutoMode_segment.allCases, id: \.self) { mode in
                    let name = mode.rawValue
                    Button {
                        if mode == .Manual || mode == .Testing {
                            AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: name)
                        }
                        autoStatus.autoMode = mode
                    } label: {
                        Text(name)
                            .font(.title)
                            .padding()
                    }
                }
            }
            
            if inProgress {
                Button(role: .destructive) {
                    AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: AutoMode.Manual.rawValue)
                } label: {
                    Text("Stop Inspection")
                        .font(.title)
                        .padding()
                }
                .keyboardShortcut("s", modifiers: .command)
            } else {
                Button {
                    AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: AutoMode.Manual.rawValue)
                } label: {
                    Label("Start Inspection", systemImage: "text.page.badge.magnifyingglass")
                        .bold()
                        .foregroundStyle(.green)
                        .padding()
                }
                .foregroundStyle(.green)
            }
        } label: {
            content
        }
    }
}

// MARK: - AutoStageView
struct AutoStageView: View {
    @EnvironmentObject var autoStatus: AutomationStatusObject
    
    private let inspectionStages: [AutoMode] = [
        .Manual, .Enter, .Drop, .Enter_Stairs, .Enter_Generator,
        .Exit_Generator, .Exit_Stairs, .Elevate, .Exit
    ]
    
    private var currentStageIndex: Int {
        let currentMode = AutoMode(rawValue: autoStatus.status.mode) ?? .Manual
        return inspectionStages.firstIndex(of: currentMode) ?? 0
    }
    
    var body: some View {
        VStack {
            ForEach(0..<inspectionStages.count, id: \.self) { index in
                Image(systemName: symbolForStage(at: index))
                    .foregroundColor(Constants.offWhite)
                    .padding()
                    .font(.title)
            }
        }
    }
    
    private func symbolForStage(at index: Int) -> String {
        let content = index != 0 ? "\(index)" : "m"
        return index == currentStageIndex ? "\(content).circle.fill" : "\(content).circle"
    }
}

// MARK: - AutoView
struct AutoView: View {
    @EnvironmentObject var autoStatus: AutomationStatusObject
    @EnvironmentObject var settings: SettingsHandler
    
    @State private var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            if viewModel.show {
                ZStack {
                    Color.clear
                    
                    VStack {
                        headerMenu
                        actionListScrollView
                        bottomStatusRow
                    }
                }
            }
        }
        .onAppear {
            viewModel.show = true
            viewModel.custom_ip = settings.ip
            viewModel.custom_cam_ip = settings.cam_ip
        }
        .onDisappear {
            viewModel.show = false
        }
        .overlay {
            if !autoStatus.status.connected {
                ProgressView("Please Wait")
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .alert("Enter custom IP", isPresented: $viewModel.showAlert) {
            TextField("Enter custom IP", text: $viewModel.custom_ip)
                .font(.caption)
            Button("Cancel", role: .cancel, action: {})
            Button("OK") {
                settings.ip = viewModel.custom_ip
            }
        } message: {
            Text("Xcode will print whatever you type.")
        }
        .alert("Enter custom camera IP", isPresented: $viewModel.showAlert_camera) {
            TextField("Enter custom camera IP", text: $viewModel.custom_cam_ip)
                .font(.caption)
            Button("Cancel", role: .cancel, action: {})
            Button("OK") {
                settings.cam_ip = viewModel.custom_cam_ip
            }
        } message: {
            Text("Xcode will print whatever you type.")
        }
    }
}

// MARK: - Subviews
extension AutoView {
    
    private var headerMenu: some View {
        let connected = autoStatus.status.connected
        let mt = autoStatus.status.action_update.isEmpty
        
        return Menu {
            Button("custom") {
                viewModel.showAlert.toggle()
            }
            .tag(viewModel.custom_ip)
            
            Text("IP : \(settings.ip)")
            
            Divider()
            
            Button("custom camera ip") {
                viewModel.showAlert_camera.toggle()
            }
            .tag(viewModel.custom_cam_ip)
            
            Text("Camera IP : \(settings.cam_ip)")
            
            Divider()
            
            Button("Change Fetch Rate") {
                viewModel.showAlert_fetch.toggle()
            }
        } label: {
            VStack {
                Text(connected ? (mt ? autoStatus.autoMode.rawValue : "Current Action") : "Server offline")
                    .padding()
                
                Text(mt ? "No Action" : autoStatus.status.action_update)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 25.0).fill(.ultraThinMaterial))
                    .padding()
            }
            .background(RoundedRectangle(cornerRadius: 33.0).fill(connected ? .green : .red))
        }
        .buttonStyle(.plain)
    }
    
    private var actionListScrollView: some View {
        ScrollViewReader { scrollView in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 40) {
                    ForEach(Array(tree2List().enumerated()), id: \.0) { _, name in
                        VStack(alignment: .leading) {
                            Text(name.replacingOccurrences(of: "-->", with: "").trimmingCharacters(in: .whitespacesAndNewlines))
                                .tint(.primary)
                            
                            if name.contains("🏃🏻‍➡️") {
                                Text(autoStatus.status.action_update)
                                    .foregroundStyle(.orange)
                                    .id("current_Action")
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 33.0).fill(.ultraThickMaterial))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .onChange(of: autoStatus.status.action_update) { _, _ in
                withAnimation {
                    scrollView.scrollTo("current_Action", anchor: .center)
                }
            }
        }
    }
    
    private var bottomStatusRow: some View {
        HStack {
            AutoMenu {
                let inProgress = (autoStatus.status.mode != "Manual")
                Image(systemName: inProgress ? "stop.fill" : "play.fill")
                    .padding()
                    .padding(.horizontal)
                    .tint(.primary)
                    .background(RoundedRectangle(cornerRadius: 33.0).fill(inProgress ? .red : .green))
            }
            
            Spacer()
            
            Text(autoStatus.status.mode)
                .lineLimit(1)
                .padding()
                .background(RoundedRectangle(cornerRadius: 33.0).fill(.ultraThickMaterial))
                .padding()
        }
    }
}

// MARK: - AutoMode & ViewModel
enum AutoMode: String, CaseIterable {
    case Manual
    case Enter
    case Exit
    case Elevate
    case Drop
    case Enter_Stairs
    case Exit_Stairs
    case Enter_Generator
    case Exit_Generator
    case Testing
}

extension AutoView {
    @Observable
    class ViewModel {
        var pop = false
        var showAlert = false
        var showAlert_camera = false
        var showAlert_fetch = false
        var custom_ip = ""
        var custom_cam_ip = ""
        var show = false
    }
    
    private func splitAndFilterLines(text: String, targetStrings: [String]) -> [String] {
        return text.split(separator: "\n")
            .map(String.init)
            .filter { line in
                targetStrings.contains { target in
                    line.lowercased().contains(target.lowercased())
                }
            }
    }
    
    private func tree2List() -> [String] {
        let tree = autoStatus.status.tree_ascii
        let better = tree
            .replacingOccurrences(of: "[o]", with: "✅")
            .replacingOccurrences(of: "[x]", with: "❌")
            .replacingOccurrences(of: "[*]", with: "🏃🏻‍➡️")
            .replacingOccurrences(of: "[-]", with: "💬")
        return splitAndFilterLines(text: better, targetStrings: ["-->"])
    }
}

#Preview {
    @Previewable var autoStatus = AutomationStatusObject()
    @Previewable var settings = SettingsHandler()
    AutoView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .environmentObject(autoStatus)
        .environmentObject(settings)
}
