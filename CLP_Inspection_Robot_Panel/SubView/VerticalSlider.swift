
import SwiftUI

/// A vertical slider replicating the iPhone Control Center volume/brightness slider
/// - Parameters:
///     - value: a Binding<Double> to set the value between 0 .. 1 by this slider
///     - onLongPress: an optional closure to call on long press to trigger some action on long press
///     - icon: an optional icon factory to show on this widget
struct VerticalSlider: View {
    @Binding var value: Double
    var referenceValue : Double?
    // Caller can optionally proivde this for long press handling
    var onLongPress: (() -> ())? = nil
    var onEnd: (() -> ())? = nil
    var icon: ((Double) -> Image)? = nil
    var text : ((Double) -> Text)? = nil
    var enabled = true
    
    // We want the slider to not jump to where the first touch land, just follow drag movement
    // So remember where the slider value is on first touch, then just adjust slider value relative
    // to that value
    @State private var startingValue = 0.0
    var sliderColor = Color(red: 221/255, green: 221/255, blue: 221/255)
    
    // For handling swipe up and down to adjust volume between 0...1
    func gesture1(geometry: GeometryProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 0)
            .onEnded { _ in
                self.startingValue = self.value
            }
            .sequenced(before: DragGesture(minimumDistance: 0)
                .onChanged {
                    let t = self.startingValue - (($0.location.y - $0.startLocation.y) / geometry.size.height)
                    withAnimation(){
                        self.value = min(max(0.0, t), 1.0)
                    }
                }
                .onEnded({ _ in
                    if let func_onEnd = self.onEnd{
                        func_onEnd()
                    }
                })
            )
    }
    
    // For use when onLongPress handling is set to handle both
    // long press gesture or swiping gesture
    func gesture2(geometry: GeometryProxy) -> some Gesture {
        LongPressGesture(maximumDistance: 0)
            .onEnded { _ in self.onLongPress!() }
            .exclusively(before: gesture1(geometry: geometry))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Color(red: 24/255, green: 24/255, blue: 24/255)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                sliderColor
                    .frame(width: geometry.size.width, height: geometry.size.height * CGFloat(self.value))
                    .cornerRadius(0)    // must do this, otherwise when the slider gesture reach max the top has rounded corner
                if let rV = self.referenceValue{
                    Color.green
                        .frame(width: geometry.size.width, height: geometry.size.height * CGFloat(rV))
                        .cornerRadius(0) 
                        .opacity(value == 0 ? 1 : 0.4)
                }
                VStack{
                    if self.icon != nil {
                        self.icon!(self.value)
                            .font(.system(size: geometry.size.width / 3.0, weight: .regular, design: .default))
                            .foregroundColor(Color(red: 70/255, green: 70/255, blue: 70/255))
                            .offset(y: -geometry.size.height / 5.0)
                        //                        .animation(.easeIn(duration: 1))
                    }
                    if self.text != nil {
                        self.text!(self.value)
                        
                            .font(.system(size: geometry.size.width / 3.0, weight: .regular, design: .default))
                            .foregroundColor(Color(red: 70/255, green: 70/255, blue: 70/255))
                        .contentTransition(.numericText(countsDown: true))
                            .offset(y: -geometry.size.height / 5.0)
                        //                        .animation(.easeIn(duration: 1))
                    }
                }
            }
            
            .cornerRadius(geometry.size.width/3.3)
            .gesture(
                self.onLongPress == nil && self.enabled ?
                AnyGesture(self.gesture1(geometry: geometry).map { _ in () }) :
                    AnyGesture(self.gesture2(geometry: geometry).map { _ in () })
            )
        }
    }
}
