import SwiftUI
import AVFoundation

/// SuccessAnimations - Delightful feedback moments
///
/// Collection of success animations and feedback that create moments of delight
/// when users complete actions, achieve goals, or reach milestones.
struct SuccessAnimations {
    
    // MARK: - Checkmark Animation
    
    /// Animated checkmark for completed actions
    struct CheckmarkAnimation: View {
        let size: CGFloat
        let color: Color
        let duration: Double
        let completion: (() -> Void)?
        
        @State private var trimEnd: CGFloat = 0
        @State private var scale: CGFloat = 0.5
        @State private var hasCompleted = false
        
        init(
            size: CGFloat = 60,
            color: Color = DSColors.success.main,
            duration: Double = 0.8,
            completion: (() -> Void)? = nil
        ) {
            self.size = size
            self.color = color
            self.duration = duration
            self.completion = completion
        }
        
        var body: some View {
            ZStack {
                // Background circle
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: size, height: size)
                    .scaleEffect(scale)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: scale)
                
                // Checkmark path
                Path { path in
                    let checkmarkFrame = CGRect(x: 0, y: 0, width: size * 0.5, height: size * 0.5)
                    let startPoint = CGPoint(x: checkmarkFrame.minX + checkmarkFrame.width * 0.2, y: checkmarkFrame.midY)
                    let midPoint = CGPoint(x: checkmarkFrame.minX + checkmarkFrame.width * 0.45, y: checkmarkFrame.maxY - checkmarkFrame.height * 0.3)
                    let endPoint = CGPoint(x: checkmarkFrame.maxX, y: checkmarkFrame.minY + checkmarkFrame.height * 0.2)
                    
                    path.move(to: startPoint)
                    path.addLine(to: midPoint)
                    path.addLine(to: endPoint)
                }
                .trim(from: 0, to: trimEnd)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round, lineJoin: .round))
                .frame(width: size, height: size)
                .scaleEffect(scale)
                .animation(.easeOut(duration: duration), value: trimEnd)
            }
            .onAppear {
                triggerHapticFeedback()
                playSoundEffect(.success)
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                    scale = 1.0
                }
                
                withAnimation(.easeOut(duration: duration).delay(0.3)) {
                    trimEnd = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
                    hasCompleted = true
                    completion?()
                }
            }
        }
        
        private func triggerHapticFeedback() {
            #if canImport(UIKit)
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
            #endif
        }
    }
    
    // MARK: - Confetti Animation
    
    /// Confetti celebration for major achievements
    struct ConfettiAnimation: View {
        let duration: Double
        let intensity: ConfettiIntensity
        let colors: [Color]
        
        @State private var isAnimating = false
        @State private var particles: [ConfettiParticle] = []
        
        init(
            duration: Double = 3.0,
            intensity: ConfettiIntensity = .medium,
            colors: [Color] = [
                DSColors.primary.main,
                DSColors.success.main,
                DSColors.warning.main,
                DSColors.error.main,
                DSColors.info.main
            ]
        ) {
            self.duration = duration
            self.intensity = intensity
            self.colors = colors
        }
        
        var body: some View {
            ZStack {
                ForEach(particles.indices, id: \.self) { index in
                    let particle = particles[index]
                    
                    RoundedRectangle(cornerRadius: particle.cornerRadius)
                        .fill(particle.color)
                        .frame(width: particle.size.width, height: particle.size.height)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .animation(
                            .easeOut(duration: particle.duration)
                            .delay(particle.delay),
                            value: isAnimating
                        )
                }
            }
            .onAppear {
                generateParticles()
                startAnimation()
                playSoundEffect(.celebration)
            }
        }
        
        private func generateParticles() {
            let particleCount = intensity.particleCount
            #if canImport(UIKit)
            let screenBounds = UIScreen.main.bounds
            #else
            let screenBounds = CGRect(x: 0, y: 0, width: 800, height: 600) // Default for macOS
            #endif
            
            particles = (0..<particleCount).map { index in
                let startX = CGFloat.random(in: -100...screenBounds.width + 100)
                let startY = CGFloat.random(in: -200...(-100))
                let endX = startX + CGFloat.random(in: -200...200)
                let endY = screenBounds.height + 200
                
                return ConfettiParticle(
                    startPosition: CGPoint(x: startX, y: startY),
                    endPosition: CGPoint(x: endX, y: endY),
                    color: colors.randomElement() ?? DSColors.primary.main,
                    size: CGSize(
                        width: CGFloat.random(in: 4...12),
                        height: CGFloat.random(in: 4...12)
                    ),
                    rotation: CGFloat.random(in: 0...360),
                    duration: Double.random(in: 2.0...4.0),
                    delay: Double.random(in: 0...1.0)
                )
            }
        }
        
        private func startAnimation() {
            withAnimation(.easeOut(duration: 0.1)) {
                isAnimating = true
            }
            
            // Update particle positions for animation
            for index in particles.indices {
                particles[index].position = particles[index].startPosition
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                for index in particles.indices {
                    particles[index].position = particles[index].endPosition
                    particles[index].opacity = 0.0
                }
            }
        }
        
        enum ConfettiIntensity {
            case light, medium, heavy
            
            var particleCount: Int {
                switch self {
                case .light: return 30
                case .medium: return 60
                case .heavy: return 100
                }
            }
        }
    }
    
    // MARK: - Coin Stack Animation
    
    /// Animated coin stack for savings milestones
    struct CoinStackAnimation: View {
        let amount: Double
        let coinCount: Int
        let completion: (() -> Void)?
        
        @State private var animatedCoins: [AnimatedCoin] = []
        @State private var hasAppeared = false
        @State private var currentAmount: Double = 0
        
        init(
            amount: Double,
            coinCount: Int = 5,
            completion: (() -> Void)? = nil
        ) {
            self.amount = amount
            self.coinCount = coinCount
            self.completion = completion
        }
        
        var body: some View {
            VStack(spacing: DSSpacing.lg) {
                // Coin stack
                ZStack {
                    ForEach(animatedCoins.indices, id: \.self) { index in
                        let coin = animatedCoins[index]
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DSColors.warning.main, DSColors.warning.w600],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text("$")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: coin.offset.x, y: coin.offset.y)
                            .scaleEffect(coin.scale)
                            .opacity(coin.opacity)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1),
                                value: hasAppeared
                            )
                    }
                }
                .frame(height: 120)
                
                // Amount counter
                VStack(spacing: DSSpacing.xs) {
                    Text("Saved")
                        .font(DSTypography.caption.regular)
                        .foregroundColor(DSColors.neutral.textSecondary)
                    
                    AnimatedNumber(value: currentAmount, format: .currency())
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(DSColors.success.main)
                }
            }
            .onAppear {
                setupCoins()
                animateCoins()
                animateAmount()
                playSoundEffect(.coinStack)
            }
        }
        
        private func setupCoins() {
            animatedCoins = (0..<coinCount).map { index in
                AnimatedCoin(
                    id: index,
                    startOffset: CGPoint(x: 0, y: -100),
                    endOffset: CGPoint(x: CGFloat.random(in: -20...20), y: CGFloat(-index * 8)),
                    scale: 0.1,
                    opacity: 0.0
                )
            }
        }
        
        private func animateCoins() {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                hasAppeared = true
                
                for index in animatedCoins.indices {
                    animatedCoins[index].offset = animatedCoins[index].endOffset
                    animatedCoins[index].scale = 1.0
                    animatedCoins[index].opacity = 1.0
                }
            }
        }
        
        private func animateAmount() {
            let stepDuration = 1.5 / Double(coinCount)
            
            for i in 0..<coinCount {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration + 0.5) {
                    let incrementAmount = amount / Double(coinCount)
                    withAnimation(.easeOut(duration: 0.3)) {
                        currentAmount += incrementAmount
                    }
                    
                    // Haptic feedback for each coin
                    #if canImport(UIKit)
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    #endif
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                completion?()
            }
        }
    }
    
    // MARK: - Star Burst Animation
    
    /// Star burst animation for perfect categorization
    struct StarBurstAnimation: View {
        let starCount: Int
        let duration: Double
        let color: Color
        
        @State private var isAnimating = false
        @State private var stars: [AnimatedStar] = []
        
        init(
            starCount: Int = 8,
            duration: Double = 2.0,
            color: Color = DSColors.warning.main
        ) {
            self.starCount = starCount
            self.duration = duration
            self.color = color
        }
        
        var body: some View {
            ZStack {
                ForEach(stars.indices, id: \.self) { index in
                    let star = stars[index]
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: star.size, weight: .semibold))
                        .foregroundColor(color)
                        .position(star.position)
                        .scaleEffect(star.scale)
                        .opacity(star.opacity)
                        .rotationEffect(.degrees(star.rotation))
                        .animation(
                            .easeOut(duration: star.duration)
                            .delay(star.delay),
                            value: isAnimating
                        )
                }
            }
            .onAppear {
                generateStars()
                startAnimation()
                playSoundEffect(.starBurst)
            }
        }
        
        private func generateStars() {
            let center = CGPoint(x: 150, y: 150) // Approximate center
            
            stars = (0..<starCount).map { index in
                let angle = (Double(index) / Double(starCount)) * 2 * .pi
                let radius = CGFloat.random(in: 80...150)
                let endX = center.x + cos(angle) * radius
                let endY = center.y + sin(angle) * radius
                
                return AnimatedStar(
                    startPosition: center,
                    endPosition: CGPoint(x: endX, y: endY),
                    size: CGFloat.random(in: 12...24),
                    duration: Double.random(in: 1.5...2.5),
                    delay: Double.random(in: 0...0.5)
                )
            }
        }
        
        private func startAnimation() {
            triggerHapticFeedback()
            
            withAnimation(.easeOut(duration: 0.1)) {
                isAnimating = true
            }
            
            // Set initial positions
            for index in stars.indices {
                stars[index].position = stars[index].startPosition
                stars[index].scale = 0.1
                stars[index].opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                for index in stars.indices {
                    stars[index].position = stars[index].endPosition
                    stars[index].scale = 1.5
                    stars[index].opacity = 0.0
                    stars[index].rotation = 360
                }
            }
        }
        
        private func triggerHapticFeedback() {
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            #endif
        }
    }
    
    // MARK: - Progress Celebration
    
    /// Animated celebration for completing progress bars
    struct ProgressCelebration: View {
        let progress: Double
        let color: Color
        let showParticles: Bool
        
        @State private var animatedProgress: Double = 0
        @State private var showingParticles = false
        @State private var pulseScale: CGFloat = 1.0
        
        init(
            progress: Double,
            color: Color = DSColors.primary.main,
            showParticles: Bool = true
        ) {
            self.progress = progress
            self.color = color
            self.showParticles = showParticles
        }
        
        var body: some View {
            ZStack {
                // Progress bar background
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.2))
                    .frame(height: 24)
                
                // Animated progress fill
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(animatedProgress))
                        .scaleEffect(y: pulseScale)
                        .animation(.spring(response: 1.2, dampingFraction: 0.8), value: animatedProgress)
                        .animation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true), value: pulseScale)
                }
                .frame(height: 24)
                
                // Sparkle particles
                if showingParticles && showParticles {
                    ParticleSystemView(color: color)
                        .transition(.opacity)
                }
            }
            .onAppear {
                startAnimation()
            }
        }
        
        private func startAnimation() {
            withAnimation(.easeOut(duration: 1.5)) {
                animatedProgress = progress
            }
            
            // Trigger pulse effect when complete
            if progress >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    triggerCompletionEffects()
                }
            }
        }
        
        private func triggerCompletionEffects() {
            withAnimation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true)) {
                pulseScale = 1.1
            }
            
            withAnimation(.easeInOut(duration: 0.5)) {
                showingParticles = true
            }
            
            #if canImport(UIKit)
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            #endif
            
            playSoundEffect(.achievement)
        }
    }
    
    // MARK: - Floating Action Success
    
    /// Success animation for floating action buttons
    struct FloatingActionSuccess: View {
        let icon: String
        let color: Color
        let completion: (() -> Void)?
        
        @State private var scale: CGFloat = 1.0
        @State private var checkmarkOpacity: Double = 0.0
        @State private var iconOpacity: Double = 1.0
        @State private var rippleScale: CGFloat = 1.0
        @State private var rippleOpacity: Double = 0.0
        
        init(
            icon: String,
            color: Color = DSColors.primary.main,
            completion: (() -> Void)? = nil
        ) {
            self.icon = icon
            self.color = color
            self.completion = completion
        }
        
        var body: some View {
            ZStack {
                // Ripple effect
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 2)
                    .scaleEffect(rippleScale)
                    .opacity(rippleOpacity)
                    .animation(.easeOut(duration: 1.0), value: rippleScale)
                
                // Button background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .scaleEffect(scale)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: scale)
                
                // Original icon
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .opacity(iconOpacity)
                    .animation(.easeOut(duration: 0.3), value: iconOpacity)
                
                // Success checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(checkmarkOpacity)
                    .scaleEffect(checkmarkOpacity)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: checkmarkOpacity)
            }
            .onAppear {
                startSuccessAnimation()
            }
        }
        
        private func startSuccessAnimation() {
            // Initial press effect
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 0.9
            }
            
            // Ripple effect
            withAnimation(.easeOut(duration: 1.0).delay(0.1)) {
                rippleScale = 2.0
                rippleOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                rippleOpacity = 0.0
            }
            
            // Icon transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.2)) {
                    iconOpacity = 0.0
                }
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                    scale = 1.0
                    checkmarkOpacity = 1.0
                }
                
                #if canImport(UIKit)
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                #endif
                
                playSoundEffect(.buttonSuccess)
            }
            
            // Return to original state
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    checkmarkOpacity = 0.0
                }
                
                withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                    iconOpacity = 1.0
                }
                
                completion?()
            }
        }
    }
}

// MARK: - Supporting Views and Models

struct ParticleSystemView: View {
    let color: Color
    @State private var particles: [SparkleParticle] = []
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(particles.indices, id: \.self) { index in
                let particle = particles[index]
                
                Circle()
                    .fill(color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
                    .animation(
                        .easeOut(duration: particle.duration)
                        .delay(particle.delay),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            generateParticles()
            startAnimation()
        }
    }
    
    private func generateParticles() {
        particles = (0..<20).map { _ in
            SparkleParticle(
                startPosition: CGPoint(x: 150, y: 12),
                endPosition: CGPoint(
                    x: CGFloat.random(in: 50...250),
                    y: CGFloat.random(in: -20...40)
                ),
                size: CGFloat.random(in: 2...6),
                duration: Double.random(in: 0.8...1.5),
                delay: Double.random(in: 0...0.3)
            )
        }
    }
    
    private func startAnimation() {
        for index in particles.indices {
            particles[index].position = particles[index].startPosition
        }
        
        withAnimation(.easeOut(duration: 0.1)) {
            isAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for index in particles.indices {
                particles[index].position = particles[index].endPosition
                particles[index].opacity = 0.0
                particles[index].scale = 0.1
            }
        }
    }
}

// MARK: - Data Models

struct ConfettiParticle {
    let startPosition: CGPoint
    let endPosition: CGPoint
    let color: Color
    let size: CGSize
    let rotation: CGFloat
    let duration: Double
    let delay: Double
    let cornerRadius: CGFloat = 2
    
    var position: CGPoint = .zero
    var opacity: Double = 1.0
    
    init(startPosition: CGPoint, endPosition: CGPoint, color: Color, size: CGSize, rotation: CGFloat, duration: Double, delay: Double) {
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.color = color
        self.size = size
        self.rotation = rotation
        self.duration = duration
        self.delay = delay
        self.position = startPosition
    }
}

struct AnimatedCoin {
    let id: Int
    let startOffset: CGPoint
    let endOffset: CGPoint
    
    var offset: CGPoint = .zero
    var scale: CGFloat = 0.1
    var opacity: Double = 0.0
}

struct AnimatedStar {
    let startPosition: CGPoint
    let endPosition: CGPoint
    let size: CGFloat
    let duration: Double
    let delay: Double
    
    var position: CGPoint = .zero
    var scale: CGFloat = 0.1
    var opacity: Double = 0.0
    var rotation: CGFloat = 0.0
    
    init(startPosition: CGPoint, endPosition: CGPoint, size: CGFloat, duration: Double, delay: Double) {
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.size = size
        self.duration = duration
        self.delay = delay
        self.position = startPosition
    }
}

struct SparkleParticle {
    let startPosition: CGPoint
    let endPosition: CGPoint
    let size: CGFloat
    let duration: Double
    let delay: Double
    
    var position: CGPoint = .zero
    var opacity: Double = 1.0
    var scale: CGFloat = 1.0
    
    init(startPosition: CGPoint, endPosition: CGPoint, size: CGFloat, duration: Double, delay: Double) {
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.size = size
        self.duration = duration
        self.delay = delay
        self.position = startPosition
    }
}

// MARK: - Sound Effects

enum SoundEffect {
    case success, celebration, coinStack, starBurst, achievement, buttonSuccess
    
    var fileName: String {
        switch self {
        case .success: return "success_chime"
        case .celebration: return "celebration_fanfare"
        case .coinStack: return "coin_stack"
        case .starBurst: return "star_burst"
        case .achievement: return "achievement_unlock"
        case .buttonSuccess: return "button_success"
        }
    }
}

func playSoundEffect(_ effect: SoundEffect) {
    // In a real implementation, you would play the sound file
    // For now, we'll just provide haptic feedback
    #if canImport(UIKit)
    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    impactFeedback.impactOccurred()
    #endif
}

// MARK: - Preview

#Preview("Success Animations") {
    TabView {
        VStack(spacing: DSSpacing.xl) {
            SuccessAnimations.CheckmarkAnimation(size: 80)
            
            Button("Trigger Checkmark") {
                // Animation will auto-trigger
            }
            .padding()
            .background(DSColors.primary.main)
            .foregroundColor(.white)
            .cornerRadius(DSSpacing.radius.lg)
        }
        .tabItem {
            Label("Checkmark", systemImage: "checkmark.circle")
        }
        
        ZStack {
            Color.black.opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: DSSpacing.xl) {
                SuccessAnimations.ConfettiAnimation(intensity: .medium)
                
                Text("🎉 Celebration! 🎉")
                    .font(DSTypography.title.title2)
                    .foregroundColor(DSColors.neutral.text)
            }
        }
        .tabItem {
            Label("Confetti", systemImage: "sparkles")
        }
        
        VStack(spacing: DSSpacing.xl) {
            SuccessAnimations.CoinStackAnimation(amount: 125.50)
            
            SuccessAnimations.StarBurstAnimation()
                .frame(width: 300, height: 300)
        }
        .tabItem {
            Label("Coins & Stars", systemImage: "star.circle")
        }
        
        VStack(spacing: DSSpacing.xl) {
            SuccessAnimations.ProgressCelebration(progress: 1.0)
                .padding(.horizontal)
            
            SuccessAnimations.FloatingActionSuccess(icon: "plus")
        }
        .tabItem {
            Label("Progress", systemImage: "progress.indicator")
        }
    }
}