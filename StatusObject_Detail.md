# Technical Report: Modernized `StatusObject` Architecture & Polling Guide

The status synchronization system has been redesigned to follow **Separation of Concerns** and **Self-Managed Lifecycles** principles. Below is a detailed report on how the structure operates now, including concrete examples of how to initiate polling.

---

## 1. Core Architecture Overview

Your status objects inherit from `BaseStatusObject<T>`, which acts as a generic controller handling **data decoding**, **network synchronization**, **state retention**, and **polling lifecycles**.

```
┌────────────────────────────────────────────────────────┐
│                      BaseStatusObject<T>               │
├────────────────────────────────────────────────────────┤
│  • status: T (Current Telemetry State)                 │
│  • isConnected (Based on network success/failure)      │
│  • logger (Context-aware OS logging)                   │
├────────────────────────────────┬───────────────────────┤
│    ▲ (Self-Managed Polling)    │ (Action Posting)      │
│    │                           ▼                       │
│  [Timer Subscription]     [Static Commands]            │
│    │                           │                       │
│    ▼                           ▼                       │
│  GET /robot_status         POST /robot/servo           │
└────────────────────────────────────────────────────────┘
```

---

## 2. Key Improvements Explained

### A. Automatic Last-Known-State Retention
*   **The Problem Before:** Any momentary packet drop or error instantly cleared all telemetry (resetting to `initialStatus`), causing gauges to reset to zero and the UI to flicker.
*   **How it Works Now:** If a request fails, the model **holds on to the last successfully fetched values** (e.g., last known joint angles/pressures) and only toggles the `.connected` boolean to `false`. This keeps the operator's interface stable while safely reporting connection status.

### B. Thread & Memory Safety
*   Using `[weak self]` in asynchronous request completions guarantees that there are no strong reference cycles (preventing memory leaks).
*   State updates are dispatched cleanly back to the main thread via `DispatchQueue.main.async`, with modern `.easeInOut` animations to make layout transitions smooth.

### C. OS Logging Categories
*   Logs are no longer generated using a generic `Logger()` instance. Instead, each subclass registers its own logger automatically using its class name as the category (e.g., `[RobotStatus]`, `[DigitalValve_Status]`), allowing you to filter logs precisely in macOS Console or Xcode.

---

## 3. How to Start/Stop Polling (Example Guide)

Since polling is self-contained within each status class, starting or stopping network polling is incredibly simple.

### Example 1: Standard Application Startup
To start pulling data in your App entry point or container view, simply call `.startPolling(settings:)` inside the `.onAppear` modifier.

```swift
struct CLP_Inspection_Robot_PanelApp: App {
    @StateObject private var settings = SettingsHandler()
    @StateObject private var robotStatus = RobotStatusObject()
    @StateObject private var digitalValveStatus = DigitalValveStatusObject()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(robotStatus)
                .environmentObject(digitalValveStatus)
                // Kicking off the polling loops self-sufficiently:
                .onAppear {
                    robotStatus.startPolling(settings: settings)
                    digitalValveStatus.startPolling(settings: settings, interval: Constants.MEDIUM_RATE)
                }
                // Optional: stop polling when the view disappears
                .onDisappear {
                    robotStatus.stopPolling()
                    digitalValveStatus.stopPolling()
                }
        }
    }
}
```

### Example 2: Accessing from a Subview
If you need to trigger polling dynamically from a manual connect/disconnect button inside a view:

```swift
struct ConnectionControlView: View {
    @EnvironmentObject var settings: SettingsHandler
    @EnvironmentObject var robotStatus: RobotStatusObject
    
    @State private var isMonitoring = true

    var body: some View {
        Button(action: {
            isMonitoring.toggle()
            if isMonitoring {
                robotStatus.startPolling(settings: settings)
            } else {
                robotStatus.stopPolling()
            }
        }) {
            Label(
                isMonitoring ? "Disconnect Monitoring" : "Connect Robot",
                systemImage: isMonitoring ? "power.circle.fill" : "power"
            )
        }
    }
}
```

---

## 4. Key Developer APIs

Every status object now exposes these three clean APIs:

| API | Parameters | Description |
| :--- | :--- | :--- |
| **`startPolling`** | `settings: SettingsHandler`, `interval: TimeInterval` | Instantly fetches once, then schedules a background timer subscription reading from `settings.ip` and `settings.port`. |
| **`stopPolling`** | *None* | Cancels the background timer subscription and stops all polling requests. |
| **`fetchStatus`** | `ip: String`, `port: Int` | Perform a single-shot manual GET request to pull telemetry data instantly. |
