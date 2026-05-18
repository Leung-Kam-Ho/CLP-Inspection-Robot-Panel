//
//  ToFView.swift
//  CLP_Inspection_Robot_Panel
//
//  Created by Kam Ho Leung on 14/7/2024.
//

import SwiftUI
import Charts

struct ToFView: View {
    @EnvironmentObject var robotStatus : RobotStatusObject
    @EnvironmentObject var digitalValveStatus : DigitalValveStatusObject
    @EnvironmentObject var launchPlatformStatus : LaunchPlatformStatusObject
    @EnvironmentObject var autoStatus : AutomationStatusObject
    @EnvironmentObject var elcidStatus : ElCidStatusObject
    @EnvironmentObject var settings : SettingsHandler
    let columns = [
        GridItem(.adaptive(minimum: 150,maximum: 200))
    ]
    var body: some View {
        let data = robotStatus.status.tof
        VStack{
            Label(String(format : "%05d",robotStatus.status.lazer), systemImage: "ruler.fill")
                .padding()
                .padding(.vertical)
                .font(.title)
                .contentTransition(.numericText(countsDown: true))
                .frame(maxWidth: .infinity,alignment: .center)
                .background(RoundedRectangle(cornerRadius: 33.0).fill(.red))
                
            ScrollView(showsIndicators: false) {
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(Array(data.enumerated()), id: \.0) { idx, value in
                        Label(String(format : "%03d",value), systemImage: "\(idx+1).circle.fill")
                            .padding()
                            .font(.title)
                            .contentTransition(.numericText(countsDown: true))
                            .foregroundStyle(value == 153 || value == 0 ? .red : Constants.offWhite)
                            .background(RoundedRectangle(cornerRadius: 33.0).fill(.ultraThickMaterial))
                    }
                }
            }
        }.padding()
            .background(RoundedRectangle(cornerRadius: 49.0).fill(.ultraThinMaterial).stroke(.white))
    }
}
