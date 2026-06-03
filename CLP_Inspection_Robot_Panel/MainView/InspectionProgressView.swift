//
//  InspectionProgressView.swift
//  CLP_Inspection_Robot_Panel
//
//  Created by Kam Ho Leung on 15/8/2024.
//

import SwiftUI

struct InspectionProgressView: View {
    @State private var tileValues: [Int] = Array(repeating: 0, count: 32)
    @State private var hoveredIndex: Int? = nil
    let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 8)

    func color(for value: Int) -> Color {
        if value == 0{
            return .black
        }
        else if value < 700 {
            return .white
        } else if value < 750 {
            return .white
        } else {
            return .white
        }
    }

    func opacityRatio(for value: Int) -> Double {
        // Map 650-800 to 1.0 to 0.5
        if value == 0 {
            return 1.0
        }
        let minValue = 640.0
        let maxValue = 800.0
        let clampedValue = max(min(Double(value), maxValue), minValue)
        return (clampedValue - minValue) / (maxValue - minValue)
    }

    func randomizeValues() {
        for i in 0..<tileValues.count {
            tileValues[i] = Int.random(in: 650...800)
        }
    }

    var body: some View {
        Button(action:{
            withAnimation(.easeInOut(duration: 0.5)) {
                randomizeValues()
            }
        }){
            GroupBox("Wedge HLD"){
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(0..<32, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color(for: tileValues[index]))
                            .opacity(opacityRatio(for: tileValues[index]))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay {
                                if hoveredIndex == index {
                                    Text(String(format: "%03d", tileValues[index]))
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .padding(4)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(4)
                                        .shadow(radius: 2)
                                        // To prevent it from being completely clipped if it's too big, 
                                        // we can allow it to layout outside slightly, though overlay is bounded
                                        .fixedSize()
                                }
                            }
                            .onHover { isHovering in
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    if isHovering {
                                        hoveredIndex = index
                                    } else if hoveredIndex == index {
                                        hoveredIndex = nil
                                    }
                                }
                            }
                            .help(String(format: "%.1f", tileValues[index]))
                    }
                }
//                .padding()
                .frame(height: 200)
            }
            .clipShape(.rect(cornerRadius: 33))
            
            
        }
        .buttonStyle(.plain)
        .onAppear {
//            randomizeValues()
        }
        
    }
}



struct InspectionSlotCardView: View {
    let slot: InspectionProgressView.Inspection_Slot_Progress
    let current_slot: Bool
    
    var body: some View {
        VStack{
                TestProgressBar(label : "EL-CID", value : slot.EL_CID_Progress, color: .green)
                //            TestProgressBar(label : "HLD", value : slot.Knocker_result, color: .blue)
                InspectionProgressView()
            
        }
        .overlay(alignment: .topTrailing, content: {
            HStack{
                Text("Slot")
                Image(systemName: "\(slot.slot_id).circle.fill")
            }
            .font(.title2)
            .padding()
        })
//        .padding()
//        .background(RoundedRectangle(cornerRadius: 33.0)
//                .fill(.ultraThickMaterial))
        .id(slot.slot_id)
        .padding()
        .font(.title)
        .contentTransition(.numericText(countsDown: true))
        .background(RoundedRectangle(cornerRadius: 49.0).fill(.ultraThinMaterial).stroke(current_slot ? .white : .clear, lineWidth: 3))
        .padding()
    }
}

extension InspectionSlotCardView{
    struct TestProgressBar: View {
        var label : String
        var value : Float?
        var color : Color
        var body: some View {
            GroupBox(label){
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 17)
                            .fill(.black)
                            .frame(height: 44)
                        RoundedRectangle(cornerRadius: 17)
                            .fill(fillColor)
                            .frame(width: max(geo.size.width * CGFloat(value ?? 0), 0), height: 44)
                            .animation(.easeInOut(duration: 0.5), value: value)
                        Text(String(format: "%.1f", (value ?? 0.0) * 100) + "%")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(textColor)
                            .frame(maxWidth: .infinity)
                            .contentTransition(.numericText(countsDown: true))
                    }
                }
                .frame(height: 44)
            }
            .clipShape(.rect(cornerRadius: 33))
        }

        private var fillColor: Color {
            // guard let v = value else { return .gray }
            // if v >= 1.0 { return color }
            // if v >= 0.7 { return .yellow }
            // if v >= 0.4 { return .orange }
            return color
        }

        private var textColor: Color {
            // guard let v = value else { return .white }
            // return v >= 0.7 ? .black : .white
            return .white
        }
    }
}

extension InspectionProgressView{
    
    struct Inspection_Slot_Progress : Codable, Hashable{
        let slot_id : Int
        let EL_CID_Progress : Float  //percentage of complete
        let Knocker_result : Float?  //percentage of loosen, nil if haven't tested
        
    }

    @Observable
    class ViewModel{
        let defaults = UserDefaults.standard
        var progress = [Inspection_Slot_Progress]()
        
        init() {
            progress = defaults.array(forKey: "inspection_progress") as? [Inspection_Slot_Progress] ?? progress_reset()
        }
        
        func progress_reset() -> [Inspection_Slot_Progress]{
            var temp = [Inspection_Slot_Progress]()
            for i in 1...30{
                temp.append(Inspection_Slot_Progress(slot_id: i, EL_CID_Progress: 0.0, Knocker_result: nil))
            }
            return temp
        }
        
        func progress_save(){
            defaults.set(progress, forKey: "inspection_progress")
        }
    }
}
