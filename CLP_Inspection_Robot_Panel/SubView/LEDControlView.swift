//
//  LEDControlView.swift
//  CLP_Inspection_Robot_Panel
//
//  Created by KamHo on 29/4/26.
//

import SwiftUI
import os

struct LEDControlView: View {
    @EnvironmentObject var settings : SettingsHandler
    @EnvironmentObject var robotStatus : RobotStatusObject
    @State var viewModel = ViewModel()
    var enabled = true
    
    var body: some View {
        VStack {
            HStack {
                VerticalSlider(value: enabled ? self.$viewModel.ledValue : .constant(0), referenceValue: nil, onEnd: {
                    if enabled {
                        let value = Int(self.viewModel.ledValue * self.viewModel.led_max)
                        // TODO: Implement actual LED control network call here
                        // Example: StatusObject.setLED(ip: settings.ip, port: settings.port, value: value)
                        RobotStatusObject.setLED(ip: settings.ip, port: settings.port, brightness: Float(value) / 100)
                        Logger().info("LED set to: \(value)")
                    }
                }, icon: { _ in
                    return Image(systemName: "lightbulb.fill")
                }, text: { _ in
                    let value = self.viewModel.ledValue * self.viewModel.led_max
                    return Text("\(Int(value))")
                },sliderColor:.orange)
                .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth:50, maxHeight: .infinity)
        .contentTransition(.numericText(countsDown: true))
    }
}

extension LEDControlView {
    @Observable
    class ViewModel {
        var ledValue: Double = 0.0
        let led_max: Double = 100.0
    }
}

#Preview {
    LEDControlView()
        .environmentObject(SettingsHandler())
}
