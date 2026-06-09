import SwiftUI

// MARK: - Chaotic, Physics-Based Falling System
struct ConfettiParticle: Identifiable {
    let id = UUID()
    
    // Blast Physics
    let targetX: CGFloat
    let targetY: CGFloat
    
    // Gravity Physics (Each particle gets unique speed!)
    let fallSpeed: Double
    let fallDuration: Double
    
    // Visuals
    let width: CGFloat
    let height: CGFloat
    let color: Color
    let finalRotation: Double
    let axisX: CGFloat
    let axisY: CGFloat
}

struct ConfettiView: View {
    @Binding var trigger: Int
    @State private var particles: [ConfettiParticle] = []
    
    // Animation states
    @State private var exploded = false
    @State private var gravityApplied = false
    
    let colors: [Color] = [
        Color(red: 1.0, green: 0.1, blue: 0.1),
        Color(red: 0.0, green: 1.0, blue: 1.0),
        Color(red: 1.0, green: 0.9, blue: 0.0),
        Color(red: 1.0, green: 0.0, blue: 1.0),
        Color(red: 0.2, green: 1.0, blue: 0.2)
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Rectangle()
                        .fill(particle.color)
                        .frame(width: particle.width, height: particle.height)
                    // Tumble
                        .rotation3DEffect(.degrees(exploded ? particle.finalRotation : 0), axis: (particle.axisX, particle.axisY, 0))
                    // Blast Out
                        .offset(x: exploded ? particle.targetX : 0, y: exploded ? particle.targetY : 0)
                        .animation(.timingCurve(0.1, 0.8, 0.2, 1, duration: 1.5), value: exploded)
                    // Unique Gravity Fall
                        .offset(y: gravityApplied ? (800 * particle.fallSpeed) : 0)
                        .animation(.easeIn(duration: particle.fallDuration), value: gravityApplied)
                        .opacity(gravityApplied ? 0 : 1)
                }
            }
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .onChange(of: trigger) { _ in igniteFireworks() }
        }
    }
    
    func igniteFireworks() {
        exploded = false
        gravityApplied = false
        
        let totalDuration = 5.0
        let blastDuration = 1.0 // Explosion happens in first second
        
        particles = (0..<1000).map { _ in
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 200...1200)
            
            return ConfettiParticle(
                targetX: cos(angle) * speed,
                targetY: sin(angle) * speed,
                
                // Fall lasts for the remainder of the 5 seconds
                fallSpeed: Double.random(in: 0.8...1.5),
                fallDuration: totalDuration - blastDuration,
                
                width: CGFloat.random(in: 3...7),
                height: CGFloat.random(in: 3...7),
                color: colors.randomElement() ?? .white,
                finalRotation: Double.random(in: 360...1440),
                axisX: CGFloat.random(in: -1...1),
                axisY: CGFloat.random(in: -1...1)
            )
        }
        
        // 1. Blast
        withAnimation(.timingCurve(0.1, 0.8, 0.2, 1, duration: blastDuration)) {
            exploded = true
        }
        
        // 2. Gravity starts immediately after blast
        DispatchQueue.main.asyncAfter(deadline: .now() + blastDuration) {
            withAnimation(.linear(duration: totalDuration - blastDuration)) {
                gravityApplied = true
            }
        }
    }
}
