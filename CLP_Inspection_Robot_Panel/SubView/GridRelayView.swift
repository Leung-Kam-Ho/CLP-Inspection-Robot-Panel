import SwiftUI
struct Robot_Image : View{

    @EnvironmentObject var robotStatus : RobotStatusObject
    @EnvironmentObject var digitalValveStatus : DigitalValveStatusObject
    @EnvironmentObject var launchPlatformStatus : LaunchPlatformStatusObject
    @EnvironmentObject var autoStatus : AutomationStatusObject
    @EnvironmentObject var elcidStatus : ElCidStatusObject
    @EnvironmentObject var settings : SettingsHandler
    var body: some View{
        ZStack{
            // forward pwm is 1100
            let leftPWM = robotStatus.status.servo[0]
            let rightPWM = robotStatus.status.servo[1]
            Image("Robot")
                .resizable()
                .scaledToFit()
            HStack(spacing : 50){
                if leftPWM < 1500 || rightPWM < 1500{
                    Text("Forward")
                        .font(.title)
                        .padding(.horizontal)
                        .tint(.primary)
                        .background(Capsule().fill(.ultraThickMaterial))
                        
                }else{
                    Image(systemName: "arrowshape.left.circle.fill")
                        .opacity(0.4)
                        .tint(.primary)
                }
                if leftPWM == 1500 && rightPWM == 1500{
                    Text("Stop")
                        .font(.title)
                        .padding(.horizontal)
                        .tint(.primary)
                        .background(Capsule().fill(.ultraThickMaterial))
                }else{
                    Image(systemName: "pause.circle.fill")
                        .tint(.primary)
                    .opacity(0.4)
                }
                if leftPWM > 1500 || rightPWM > 1500{
                    Text("Backward")
                        .font(.title)
                        .padding(.horizontal)
                        .tint(.primary)
                        .background(Capsule().fill(.ultraThickMaterial))
                }else{
                    Image(systemName: "arrowshape.right.circle.fill")
                        .tint(.primary)
                        .opacity(0.4)
                }
            }
            
        }.lineLimit(1)
    }
}
struct GridRelayView : View{
    @EnvironmentObject var robotStatus : RobotStatusObject
    let notBlack = Color(red: 24/255, green: 24/255, blue: 24/255)
    var pressure_view = true
    var body: some View{
        VStack{
            VStack{
//                Robot_Image()
                
                VStack(spacing : 20){
                    HStack{
                        ForEach(1...4, id:\.self){ idx in
                                let opened = get_state(idx)
                            
                                HStack{
                                    Text("F")
                                    Image(systemName: "\(idx).circle.fill")
                                }
                                    .padding()
                                    .foregroundStyle(Constants.offWhite)
                                    .background(RoundedRectangle(cornerRadius: 25.0)
                                        .fill(opened ? .green : notBlack))
                            if idx != 4{
                                Spacer()
                            }
                        }
                    }
                    if pressure_view{
                        PressureView(enabled : false)
                            .disabled(true)
                    }
                    
                    HStack{
                        Section{
                            let idx = 8
                            let opened = get_state(idx)
                            //                                        let state = "1"
                            
//                            Image(systemName: "\(idx).circle.fill")
                            Text("Tapper")
                                .padding()
                                .tint(.primary)
                                .foregroundStyle(Constants.offWhite)
                                .background(RoundedRectangle(cornerRadius: 25.0)
                                    .fill(opened ? .orange : notBlack))
    //                            .foregroundStyle(.background)
                        }
                        Spacer()
                        Section{
                            let idx = 7
                            let opened = get_state(idx)
//                            Image(systemName: "\(idx).circle.fill")
                            Text("EL-CID")
                                .padding()
                                .foregroundStyle(Constants.offWhite)
                                .tint(.primary)
                                .background( RoundedRectangle(cornerRadius: 25.0)
                                    .fill(opened ? .orange : notBlack))
                        }
                        Spacer()
                        
                        ForEach(5...6, id:\.self){ idx in
                                let opened = get_state(idx)
                                HStack{
                                    Text("T")
                                    Image(systemName: "\(idx-4).circle.fill")
                                }
                                    .padding()
                                    .foregroundStyle(Constants.offWhite)
                                    
                                    .background(RoundedRectangle(cornerRadius: 25.0)
                                        .fill(opened ? .green : notBlack))
                            if idx != 6{
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        
    }
    func get_state(_ idx : Int) -> Bool{
        let s = robotStatus.status.relay
        let index = s.index(s.startIndex, offsetBy: idx-1)
        return String(robotStatus.status.relay[index]) == "1"
    }
}
