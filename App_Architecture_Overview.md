# Technical Report: CLP Inspection Robot Panel — App Architecture Overview

The application is an **iPad-first / macOS** SwiftUI control panel for a CLP inspection robot, structured around **MVVM + EnvironmentObject dependency injection** with **self-managed polling lifecycles** across six telemetry subsystems.

---

## 1. Core Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CLP_Inspection_Robot_PanelApp                        │
│                         (@main — iOS / macOS)                               │
│                                                                             │
│  Creates + owns:                                                            │
│    SettingsHandler (1) ────────┐                                            │
│    RobotStatusObject (6) ──────┤                                            │
│    LaunchPlatformStatusObject  ├── .environmentObject() ──► All Views       │
│    AutomationStatusObject      │                                            │
│    ElCidStatusObject           │                                            │
│    DigitalValveStatusObject    │                                            │
│    FBGStatusObject             │                                            │
│                                                                             │
│  .onAppear: starts polling on all 6 objects    .onDisappear: (optional)     │
└───────────────────────────────────┬─────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    ▼                               ▼
          ┌─────────────────┐            ┌────────────────────┐
          │   iOS:           │            │  macOS:             │
          │   ContentView()  │            │  UserView()         │
          │   (TabView)      │            │  (Operator Layout)  │
          └────────┬────────┘            └─────────┬──────────┘
                   │                               │
                   │                               ├── sidebarControlView
                   │                               │     ├── LEDControlView
                   │                               │     └── AutoStageView
                   │                               │
                   │                               ├── launchPlatformButton
                   │                               ├── robotButton (GridRelayView)
                   │                               ├── TabView (30 InspectionSlotCardView)
                   │                               └── ContentView() (embedded)
                   │
    ┌──────────────┼──────────────┬───────────────┬┐
    ▼              ▼              ▼               ▼▼
┌────────┐ ┌────────────┐ ┌──────────────┐ ┌──────────┐
│ Auto   │ │ All        │ │ Robot        │ │ Launch   │
│ Tab    │ │ (Concept)  │ │ Tab          │ │ Platform │
├────────┤ ├────────────┤ ├──────────────┤ │ Tab      │
│AutoView│ │SensorBar   │ │ControlView   │ ├──────────┤
│        │ │FBGView     │ │ ├─LEDControl │ │Drag-to-  │
│  tree  │ │GridRelay   │ │ ├─Relays 1-8 │ │rotate    │
│  ascii │ │LaunchPlatfm│ │ ├─Left/Right │ │widget    │
│  parser│ │AutoView    │ │ │  sliders   │ │          │
│        │ │            │ │ ├─AutoMenu   │ │Angle/slot│
│header +│ │            │ │ ├─Servo ctrl │ │display   │
│status   │ │            │ │ ├─ToF readout│ │Relays    │
└────────┘ └────────────┘ │ └─AutoControl│ │Setpoint  │
                          └──────────────┘ └──────────┘
 ┌──────────┐ ┌──────┐ ┌──────────┐ ┌──────────────┐
 │ Pressure │ │ ToF  │ │ LED      │ │ Camera (WIP) │
 │ Tab      │ │ Tab  │ │ Tab      │ │              │
 ├──────────┤ ├──────┤ ├──────────┤ ├──────────────┤
 │PressureV │ │ToFView│ │LEDCtrlV  │ │Camera_WebView│
 │4xVSlider │ │Lazer │ │VSlider   │ │(WKWebView)   │
 │          │ │18 sens│ │brightness│ │              │
 └──────────┘ └──────┘ └──────────┘ └──────────────┘
```

---

## 2. Three-Layer Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  VIEW LAYER  (SwiftUI Views)                                     │
│                                                                  │
│  MainView/         SubView/                                      │
│  ├─ ContentView   ├─ VerticalSlider    ├─ LEDControlView         │
│  ├─ ControlView   ├─ GridRelayView     ├─ FBGView               │
│  ├─ ConceptView   ├─ SensorBarView     ├─ ToFChartView          │
│  ├─ AutoView      ├─ ToFView           ├─ AutoControlView       │
│  ├─ UserView      ├─ SensorView        ├─ WebView               │
│  ├─ PressureView  ├─ InspectionProgressView                      │
│  └─ LaunchPlatformView                                           │
│                                                                  │
│  EnvironmentObject injection: @EnvironmentObject for all 7 objs  │
│  Local state: @State, @Observable ViewModel classes              │
├──────────────────────────────────────────────────────────────────┤
│  VIEWMODEL / SERVICE LAYER  (ObservableObject + Combine)         │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐      │
│  │  BaseStatusObject<T: Decodable & Equatable>            │      │
│  │  ┌─ @Published var status: T                           │      │
│  │  ├─ Combine Timer.publish → fetchStatus every interval │      │
│  │  ├─ Last-known-state retention on failure              │      │
│  │  ├─ Static sendCommand for POST requests               │      │
│  │  └─ OSLog per subclass via String(describing: T.self)  │      │
│  │                                                        │      │
│  │  Subclasses + their T + route + static commands:       │      │
│  │  RobotStatusObject    RobotStatus       /robot_status   │      │
│  │    setServo / setRelay / setLED                         │      │
│  │  LaunchPlatformStatusObject  LaunchPlatformStatus       │      │
│  │    RotatePlatform / setRelay   /launch_platform_status  │      │
│  │  AutomationStatusObject       AutomationStatus          │      │
│  │    setMode                     /auto_status             │      │
│  │  ElCidStatusObject            ElCidstatus               │      │
│  │    setRelay                   /el_cid_status            │      │
│  │  DigitalValveStatusObject     DigitalValve_Status       │      │
│  │    setPressure                /digital_valve_status     │      │
│  │  FBGStatusObject             FBGStatus                  │      │
│  │    setTarget / resetTarget    /fbg_status               │      │
│  └────────────────────────────────────────────────────────┘      │
│                                                                  │
│  ViewModels per View (iOS 17 @Observable macro):                  │
│  ContentView.ViewModel, ControlView.ViewModel,                   │
│  LaunchPlatformView.ViewModel, AutoView.ViewModel,               │
│  InspectionProgressView.ViewModel, PressureView.ViewModel,       │
│  LEDControlView.ViewModel                                         │
├──────────────────────────────────────────────────────────────────┤
│  MODEL LAYER  (DeviceStatus.swift — Codable Data Classes)        │
│                                                                  │
│  RobotStatus        servo[4], relay(String8), tof[18], lazer    │
│  DigitalValve_Status   pressure[4] (Double)                      │
│  LaunchPlatformStatus  angle, relay, setpoint, lazer             │
│  AutomationStatus      mode, action_update, tree_ascii           │
│  AudioStatus           (FFT, Audio arrays — not actively polled) │
│  ElCidstatus           distance_per_click, relay_state            │
│  FBGStatus             feet[4], tank[4]                           │
│                                                                  │
│  All conform to: Codable, ObservableObject, Equatable            │
│  All have: var connected: Bool (via ConnectableStatus protocol)  │
├──────────────────────────────────────────────────────────────────┤
│  NETWORKING LAYER  (NetworkManager — Singleton)                  │
│                                                                  │
│  GET  http://{ip}:{port}/{route}  → JSONDecoder → T             │
│  POST http://{ip}:{port}/{route}  → ["value": V]                │
│  1-second timeout on all requests                                │
└──────────────────────────────────────────────────────────────────┘
```

---

## 3. Dependency Injection & Ownership

```
CLP_Inspection_Robot_PanelApp
  @StateObject  settings ─────────────── SettingsHandler (AppStorage-backed)
  @StateObject  robotStatus ──────────── RobotStatusObject
  @StateObject  launchPlatformStatus ─── LaunchPlatformStatusObject
  @StateObject  automationStatus ─────── AutomationStatusObject
  @StateObject  elCidStatus ──────────── ElCidStatusObject
  @StateObject  digitalValveStatus ───── DigitalValveStatusObject
  @StateObject  fbgStatus ────────────── FBGStatusObject
       │
       ├── .environmentObject() ──► All descendant views
       │
       └── .onAppear ──► startPolling(settings:) on all 6
```

### View-to-StatusObject dependency matrix:

| View | `settings` | `robotStatus` | `launchPlatformStatus` | `autoStatus` | `digitalValveStatus` | `elcidStatus` | `fbgStatus` |
|------|:----------:|:-------------:|:----------------------:|:------------:|:--------------------:|:-------------:|:-----------:|
| **ContentView** | Y | Y | Y | Y | Y | Y | - |
| **ControlView** | Y | Y | Y | Y | - | - | - |
| **ConceptView** | Y | Y | Y | - | Y | Y | Y |
| **UserView** | Y | Y | Y | Y | - | - | - |
| **LaunchPlatformView** | Y | - | Y | - | Y | Y | - |
| **AutoView** | Y | - | - | Y | - | - | - |
| **PressureView** | Y | - | - | - | Y | - | - |
| **ToFView** | Y | Y | Y | Y | Y | Y | - |
| **SensorBarView** | - | Y | - | - | - | - | - |
| **FBGView** | Y | - | - | - | - | - | Y |
| **GridRelayView** | Y | Y | - | - | - | - | - |
| **LEDControlView** | Y | Y | - | - | - | - | - |
| **AutoControlView** | Y | - | - | Y | - | - | - |
| **EL_CID_TriggerButton** | Y | - | - | - | - | Y | - |

---

## 4. Data Flow Patterns

### A. Polling (Read) Flow
```
Timer.publish (Combine, every N seconds)
  → BaseStatusObject.fetchStatus()
    → NetworkManager.getRequest()    GET http://{ip}:{port}/{route}
      → JSONDecoder.decode(T.self)
        → BaseStatusObject.status = newStatus  (main thread, with .easeInOut)
          → @Published triggers SwiftUI re-render via @EnvironmentObject
```

### B. Command (Write) Flow
```
UI Button tap
  → StatusObject subclass static method (e.g. RobotStatusObject.setServo)
    → BaseStatusObject.sendCommand()   POST http://{ip}:{port}/{route}
      → NetworkManager.postRequest()   ["value": commandData]
        → URLSession dataTask → completion callback (Bool)
```

### C. Settings Flow
```
SettingsHandler (ObservableObject)
  @AppStorage("rosIP")       default: "localhost"
  @AppStorage("rosPort")     default: 5000
  @AppStorage("cameraIP")    default: "localhost"
  @AppStorage("cameraPort")  default: 4000
  @AppStorage("updateRate")  default: 1.0
  @AppStorage("forceUserView") default: false
       │
       └── @EnvironmentObject → read by all Views + StatusObjects
```

---

## 5. Key Design Patterns

| Pattern | Where Used |
|---------|-----------|
| **Singleton** | `NetworkManager.shared` |
| **Generic Base Class** | `BaseStatusObject<T: Decodable & Equatable>` — template method for polling/commands |
| **Protocol (ConnectableStatus)** | Standardizes `connected` property across all 6 telemetry models |
| **Dependency Injection** | SwiftUI `@EnvironmentObject` for all 7 environment objects |
| **Observer / Reactive** | Combine `Timer.publish` + `.sink` for polling; `@Published` for UI binding |
| **Last-Known-State Retention** | On fetch failure, status retains previous values; only toggles `connected = false` |
| **OSLog Per-Category** | Each subclass auto-registers `Logger(category: String(describing: T.self))` |
| **iOS 17 @Observable** | Local ViewModel classes in ContentView, ControlView, LaunchPlatformView, etc. |
| **UIViewRepresentable** | `WebView` wraps `WKWebView` for camera stream |
| **FileDocument** | `TextFile` for save-to-file export |
| **AppStorage** | `SettingsHandler` persists IP, port, camera config to UserDefaults |

---

## 6. View Hierarchy

```
iOS @main:
  CLP_Inspection_Robot_PanelApp
    └─ WindowGroup
         └─ ContentView()
              └─ TabView (page style, 7 tabs)
                   ├─ "Auto"        → AutoView()
                   ├─ "All"         → ConceptView()       [iPad only]
                   │                   ├─ SensorBarView (Lazer + SensorTabsView)
                   │                   ├─ FBGView
                   │                   ├─ GridRelayView (w/ PressureView)
                   │                   ├─ LaunchPlatformView
                   │                   └─ AutoView
                   ├─ "Robot"       → ControlView()
                   │                   ├─ LEDControlView
                   │                   ├─ Relay buttons (×8)
                   │                   ├─ PressureView + Left/Right sliders
                   │                   ├─ FBGView + ToFChartView
                   │                   └─ AutoControlView (▲/■/▼)
                   ├─ "Launch Platform" → LaunchPlatformView()
                   ├─ "Pressure"    → PressureView() (4× VerticalSlider)
                   ├─ "ToF"         → ToFView()
                   └─ "LED"         → LEDControlView()

macOS @main:
  CLP_Inspection_Robot_PanelApp
    └─ WindowGroup
         └─ GeometryReader
              ├─ [compact/fullscreen] → UserView()
              │                        ├─ Sidebar: LEDControlView + AutoStageView
              │                        ├─ LaunchPlatform button
              │                        ├─ Robot button (GridRelayView)
              │                        ├─ TabView (30× InspectionSlotCardView)
              │                        └─ Automation controls
              └─ [large] → ContentView()  (same as iOS)
```

---

## 7. Polling Lifecycle Summary

All 6 status objects share the same startup pattern. Each runs autonomously once started:

| Status Object | Route | Default Interval | Static Command Methods |
|--------------|-------|:----------------:|------------------------|
| `RobotStatusObject` | `/robot_status` | 1.0s | `setServo`, `setRelay`, `setLED` |
| `LaunchPlatformStatusObject` | `/launch_platform_status` | 1.0s | `RotatePlatform`, `setRelay` |
| `AutomationStatusObject` | `/auto_status` | 1.0s | `setMode` |
| `ElCidStatusObject` | `/el_cid_status` | 1.0s | `setRelay` |
| `DigitalValveStatusObject` | `/digital_valve_status` | 1.0s | `setPressure` |
| `FBGStatusObject` | `/fbg_status` | 1.0s | `setTarget`, `resetTarget` |

All are started in `.onAppear` via `startPolling(settings:)` and can be individually stopped via `stopPolling()`. Interval can be overridden per call.

---

## 8. Key Developer APIs

### Status Object APIs (per `BaseStatusObject`)

| API | Parameters | Description |
| :--- | :--- | :--- |
| **`startPolling`** | `settings: SettingsHandler`, `interval: TimeInterval` | Fetches once immediately, then schedules timer-based polling using `settings.ip/port` |
| **`stopPolling`** | *None* | Cancels the Combine timer subscription |
| **`fetchStatus`** | `ip: String`, `port: Int` | Single-shot manual GET to refresh telemetry |
| **`sendCommand`** (static) | `ip`, `port`, `route`, `data: Encodable` | Generic POST to send any command payload |

### ViewModel Pattern (per major view)

| View | ViewModel Class | Key State |
|------|----------------|-----------|
| `ContentView` | `ContentView.ViewModel` | `selectedTab: Tabs` |
| `ControlView` | `ControlView.ViewModel` | `l`, `r` (slider values), `leftPower`, `rightPower` |
| `LaunchPlatformView` | `LaunchPlatformView.ViewModel` | `previewLP_angle`, `locked` (slot snap) |
| `AutoView` | `AutoView.ViewModel` | `custom_ip`, `showAlert` |
| `InspectionProgressView` | `InspectionProgressView.ViewModel` | `progress: [Inspection_Slot_Progress]` (UserDefaults-backed) |

### Networking API (per `NetworkManager`)

| API | Signature | Description |
| :--- | :--- | :--- |
| **`getRequest`** | `<T: Decodable>(ip, port, route, completion: Result<T, Error>)` | GET + JSON decode |
| **`postRequest`** | `<V: Encodable>(ip, port, route, value: V, completion: Bool?)` | POST with `["value": V]` envelope |
| **`createURL`** | `(ip, port, route) -> URL` | Builds `http://{ip}:{port}{route}` |
