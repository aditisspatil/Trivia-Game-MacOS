import SwiftUI

// Draws a classic heart shape using Path.
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let center = CGPoint(x: width / 2, y: height / 2)
        let topCurveHeight = height * 0.3
        
        // Left top curve
        path.move(to: CGPoint(x: center.x, y: height))
        path.addCurve(to: CGPoint(x: 0, y: topCurveHeight),
            control1: CGPoint(x: center.x, y: height * 0.7),
            control2: CGPoint(x: 0, y: height * 0.55))
        // Top center dip
        path.addArc(center: CGPoint(x: width * 0.25, y: topCurveHeight),
                    radius: width * 0.25,
                    startAngle: Angle(degrees: 180),
                    endAngle: Angle(degrees: 0),
                    clockwise: false)
        // Right top curve
        path.addArc(center: CGPoint(x: width * 0.75, y: topCurveHeight),
                    radius: width * 0.25,
                    startAngle: Angle(degrees: 180),
                    endAngle: Angle(degrees: 0),
                    clockwise: false)
        // Back to bottom
        path.addCurve(to: CGPoint(x: center.x, y: height),
            control1: CGPoint(x: width, y: height * 0.55),
            control2: CGPoint(x: center.x, y: height * 0.7))
        return path
    }
}

struct HeartParticle: Identifiable {
    let id = UUID()
    let position: CGPoint
    let scale: CGFloat
}

struct HeartView: View {
    @Binding var trigger: Int  // Increment to trigger animation
    @State private var hearts: [HeartParticle] = []
    @State private var animateBeat = false
    @State private var animateOut = false
    
    // Number and variability of hearts
    let heartCount = 400
    let minScale: CGFloat = 10
    let maxScale: CGFloat = 20
    let heartColor = Color.red
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(hearts) { heart in
                    Image(systemName: "heart.fill")
                        .foregroundColor(heartColor)
                        .frame(width: 40 * heart.scale, height: 36 * heart.scale)
                        .scaleEffect(
                            animateOut ? 2.6 : (animateBeat ? 1.2 : 1.0)
                        )
                        .opacity(
                            animateOut ? 0 : 1
                        )
                        .position(x: heart.position.x, y: heart.position.y)
                        .animation(
                            .easeInOut(duration: animateBeat ? 0.13 : 0.15),
                            value: animateBeat
                        )
                        .animation(
                            .easeInOut(duration: 3).delay(0.47),
                            value: animateOut
                        )
                    
                }
            }
            .onChange(of: trigger) {
                showHearts(in: geo.size)
            }
        }
    }

    // Generates hearts all over the screen and animates them
    func showHearts(in size: CGSize) {
        let w = size.width
        let h = size.height
        hearts = (0..<heartCount).map { _ in
            HeartParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 30...(w-30)),
                    y: CGFloat.random(in: 40...(h-32))
                ),
                scale: CGFloat.random(in: minScale...maxScale)
            )
        }
        animateBeat = false
        animateOut = false
        // Animate beat (scale up and down)
        DispatchQueue.main.async {
            withAnimation { animateBeat = true }
            // Beat resets after a pulse (0.2s), then fades out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                withAnimation { animateBeat = false }
                // Start fade/scale out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation { animateOut = true }
                }
            }
        }
    }
}
