import SwiftUI

struct BalloonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Draw balloon (ellipse for bulb, line for string)
        let balloonRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height * 0.8)
        path.addEllipse(in: balloonRect)
        // Draw the string as a curve
        let start = CGPoint(x: rect.midX, y: balloonRect.maxY)
        let end = CGPoint(x: rect.midX, y: rect.maxY)
        let control1 = CGPoint(x: rect.midX - rect.width*0.1, y: balloonRect.maxY + rect.height*0.05)
        let control2 = CGPoint(x: rect.midX + rect.width*0.1, y: balloonRect.maxY + rect.height*0.25)
        path.move(to: start)
        path.addCurve(to: end, control1: control1, control2: control2)
        return path
    }
}

// MARK: - Animated, Screen-Filling Hearts Effect
struct BalloonParticle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let endX: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    let scale: CGFloat
    let color: Color
    let duration: Double
    let delay: Double
    let rotation: Double
}

struct BalloonView: View {
    @Binding var trigger: Int
    @State private var particles: [BalloonParticle] = []
    @State private var animate = false
    
    @StateObject private var audioManager = AudioManager()

    let colors: [Color] = [
        .red, .pink, .purple, .orange, .yellow, .mint
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    BalloonShape()
                        .aspectRatio(0.75, contentMode: .fit)
                        .foregroundColor(particle.color)
                        .frame(width: 30 * particle.scale, height: 28 * particle.scale)
                        .rotationEffect(.degrees(animate ? particle.rotation : 0))
                        .position(x: animate ? particle.endX : particle.startX,
                                  y: animate ? particle.endY : particle.startY)
                        .opacity(animate ? 0 : 1)
                        .animation(
                            .easeInOut(duration: particle.duration)
                                .delay(particle.delay),
                            value: animate
                        )
                }
            }
            .onChange(of: trigger) { _ in
                // 2. Play the sound! (Make sure the name matches your file exactly)
                audioManager.playSound(soundName: "confetti", fileExtension: "mp3")
                
                // 3. Trigger the animation
                launchBalloons(geo: geo)
            }
        }
    }

    func launchBalloons(geo: GeometryProxy) {
        animate = false
        let width = geo.size.width
        let height = geo.size.height
        let count = Int(width/4) // Density of hearts

        particles = (0..<count).map { _ in
            let startX = CGFloat.random(in: 0-50...width+50)
            let endX = CGFloat.random(in: startX-200...startX+300)
            let startY = CGFloat.random(in: height+20...(height+20))
            let endY = CGFloat.random(in: -60...(-10))
            let scale = CGFloat.random(in: 0.7...1.6)
            let color = colors.randomElement() ?? .red
            let duration = Double.random(in: 2...4)
            let delay = Double.random(in: 0.0...2.0)
            let rotation = Double.random(in: -50...5)

            return BalloonParticle(
                startX: startX,
                endX: endX,
                startY: startY,
                endY: endY,
                scale: scale,
                color: color,
                duration: duration,
                delay: delay,
                rotation: rotation
            )
        }

        // Trigger animation after particles are set
        DispatchQueue.main.async {
            animate = true
        }
    }
}
