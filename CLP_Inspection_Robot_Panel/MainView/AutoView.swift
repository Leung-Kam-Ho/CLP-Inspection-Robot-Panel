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
        Menu(content: {
            let inProgress = (self.autoStatus.status.mode != "Manual")
            
            Section {
                ForEach(AutomationStatus.AutoMode_segment.allCases, id: \.self) { mode in
                    let name = mode.rawValue
                    Button(action: {
                        switch mode {
                        case .Manual, .Testing:
                            AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: name)
                        default:
                            autoStatus.autoMode = mode
                        }
                        autoStatus.autoMode = mode
                    }, label: {
                        Text(name)
                            .font(.title)
                            .padding()
                    })
                }
            }
            
            if inProgress {
                Button(role: .destructive, action: {
                    AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: AutoMode.Manual.rawValue)
                }, label: {
                    Text("Stop Inspection")
                        .font(.title)
                        .padding()
                })
                .keyboardShortcut("s", modifiers: .command)
            } else {
                Button(action: {
                    AutomationStatusObject.setMode(ip: settings.ip, port: settings.port, mode: AutoMode.Manual.rawValue)
                }, label: {
                    Label("Start Inspection", systemImage: "text.page.badge.magnifyingglass")
                        .bold()
                        .foregroundStyle(.green)
                        .padding()
                })
                .foregroundStyle(.green)
            }
        }, label: {
            self.content
        })
    }
}

struct AutoStageView: View {
    var totaleStage : Int = 6
    var currentStage : Int = 0
    
    var body: some View {
        VStack{
            ForEach(0..<totaleStage, id: \.self) { index in
                Image(systemName: index == currentStage ? "\(index+1).circle.fill" : "\(index+1).circle")
                    .foregroundColor(Constants.offWhite)
                    .padding()
                    .font(.title)
            }
            
        }
    }
}

// MARK: - AutoView
struct AutoView: View {
    @EnvironmentObject var autoStatus: AutomationStatusObject
    @EnvironmentObject var settings: SettingsHandler
    
    @State var viewModel = ViewModel()
    
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
            Button("OK", action: {
                settings.ip = viewModel.custom_ip
            })
        } message: {
            Text("Xcode will print whatever you type.")
        }
        .alert("Enter custom camera IP", isPresented: $viewModel.showAlert_camera) {
            TextField("Enter custom camera IP", text: $viewModel.custom_cam_ip)
                .font(.caption)
            Button("Cancel", role: .cancel, action: {})
            Button("OK", action: {
                settings.cam_ip = viewModel.custom_cam_ip
            })
        } message: {
            Text("Xcode will print whatever you type.")
        }
    }
}

// MARK: - Subviews
extension AutoView {
    
    private var headerMenu: some View {
        let connected = autoStatus.status.connected
        return Menu(content: {
            Button("custom") {
                viewModel.showAlert.toggle()
            }.tag(viewModel.custom_ip)
            
            Text("IP : \(settings.ip)")
            
            Divider()
            
            Button("custom camera ip") {
                viewModel.showAlert_camera.toggle()
            }.tag(viewModel.custom_cam_ip)
            
            Text("Camera IP : \(settings.cam_ip)")
            
            Divider()
            
            Button("Change Fetch Rate") {
                viewModel.showAlert_fetch.toggle()
            }
        }, label: {
            VStack {
                let mt = autoStatus.status.action_update == ""
                Text(connected ? (mt ? self.autoStatus.autoMode.rawValue : "Current Action") : "Server offline")
                    .padding()
                    .contentTransition(.numericText(countsDown: true))
                
                Text(autoStatus.status.action_update == "" ? "No Action" : autoStatus.status.action_update)
                    .padding()
                    .contentTransition(.numericText(countsDown: true))
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 25.0).fill(.ultraThinMaterial))
                    .padding()
            }
            .background(RoundedRectangle(cornerRadius: 33.0).fill(connected ? .green : .red))
        })
        .buttonStyle(.plain)
    }
    
    private var actionListScrollView: some View {
        ScrollViewReader { scrollView in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 40) {
                    ForEach(Array(tree2List().enumerated()), id: \.0) { idx, name in
                        VStack(alignment: .leading) {
                            Text(name.replacingOccurrences(of: "-->", with: "").trimmingCharacters(in: .whitespacesAndNewlines))
                                .tint(.primary)
                                .contentTransition(.numericText(countsDown: true))
                            
                            if name.contains("🏃🏻‍➡️") {
                                Text(autoStatus.status.action_update)
                                    .foregroundStyle(.orange)
                                    .id("current_Action")
                                    .contentTransition(.numericText(countsDown: true))
                                    .onAppear {
                                        scrollView.scrollTo("current_Action")
                                    }
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 33.0).fill(.ultraThickMaterial))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
    }
    
    private var bottomStatusRow: some View {
        HStack {
            AutoMenu(content: {
                let inProgress = (autoStatus.status.mode != "Manual")
                Image(systemName: inProgress ? "stop.fill" : "play.fill")
                    .padding()
                    .padding(.horizontal)
                    .tint(.primary)
                    .background(RoundedRectangle(cornerRadius: 33.0).fill(inProgress ? .red : .green))
            })
            
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
    
    func splitAndFilterLines(text: String, targetStrings: [String]) -> [String] {
        return text.split(separator: "\n")
            .map(String.init)
            .filter { line in
                targetStrings.contains { target in
                    line.lowercased().contains(target.lowercased())
                }
            }
    }
    
    func tree2List() -> [String] {
        let tree = autoStatus.status.tree_ascii
        let better = tree
            .replacingOccurrences(of: "[o]", with: "✅")
            .replacingOccurrences(of: "[x]", with: "❌")
            .replacingOccurrences(of: "[*]", with: "🏃🏻‍➡️")
            .replacingOccurrences(of: "[-]", with: "💬")
        let filtered = splitAndFilterLines(text: better, targetStrings: ["-->"])
        return filtered
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
