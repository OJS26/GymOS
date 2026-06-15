import SwiftUI
import Foundation

// MARK: - Theme System
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .dark
    
    enum AppTheme: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
    }
    
    init() {
        self.loadTheme()
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        saveTheme()
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
    }
    
    private func loadTheme() {
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        } else {
            currentTheme = .dark // Default to dark
        }
    }
}

// MARK: - Color Palette
struct GymOSColors {
    
    // MARK: - Dark Theme Colors
    static let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.07) // Very dark grey
    static let darkSecondaryBackground = Color(red: 0.1, green: 0.1, blue: 0.12) // Dark grey
    static let darkCardBackground = Color(red: 0.12, green: 0.12, blue: 0.15) // Card background
    static let darkElevatedBackground = Color(red: 0.15, green: 0.15, blue: 0.18) // Elevated elements
    
    // MARK: - Light Theme Colors
    static let lightBackground = Color(red: 0.98, green: 0.98, blue: 0.99)
    static let lightSecondaryBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let lightCardBackground = Color.white
    static let lightElevatedBackground = Color(red: 0.97, green: 0.97, blue: 0.98)
    
    // MARK: - Purple Accent Colors
    static let primaryPurple = Color(red: 0.45, green: 0.35, blue: 0.85) // Main purple
    static let lightPurple = Color(red: 0.55, green: 0.45, blue: 0.95) // Lighter purple
    static let darkPurple = Color(red: 0.35, green: 0.25, blue: 0.75) // Darker purple
    static let purpleGradient = LinearGradient(
        colors: [primaryPurple, lightPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Status Colors
    static let successGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let warningOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let dangerRed = Color(red: 0.9, green: 0.3, blue: 0.3)
    static let infoBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    // MARK: - Text Colors
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let tertiaryText = Color(red: 0.6, green: 0.6, blue: 0.65)
    
    // MARK: - Dynamic Colors (adapt to theme)
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkBackground : lightBackground
    }
    
    static func secondaryBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkSecondaryBackground : lightSecondaryBackground
    }
    
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkCardBackground : lightCardBackground
    }
    
    static func elevatedBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkElevatedBackground : lightElevatedBackground
    }
}

// MARK: - Custom View Modifiers
struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    init(padding: CGFloat = 16, cornerRadius: CGFloat = 16) {
        self.padding = padding
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(GymOSColors.cardBackground(for: colorScheme))
                    .shadow(
                        color: colorScheme == .dark ?
                            Color.black.opacity(0.3) : Color.black.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
    }
}

struct GlassCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 16) {
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        colorScheme == .dark ?
                            Color.white.opacity(0.05) : Color.black.opacity(0.02)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                colorScheme == .dark ?
                                    Color.white.opacity(0.1) : Color.black.opacity(0.05),
                                lineWidth: 1
                            )
                    )
            )
    }
}

struct PurpleButtonStyle: ButtonStyle {
    let variant: Variant
    @Environment(\.colorScheme) var colorScheme
    
    enum Variant {
        case filled, bordered, minimal
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundForVariant(configuration.isPressed))
            .foregroundColor(textColorForVariant)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func backgroundForVariant(_ isPressed: Bool) -> some View {
        Group {
            switch variant {
            case .filled:
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPressed ? GymOSColors.darkPurple : GymOSColors.primaryPurple)
            case .bordered:
                RoundedRectangle(cornerRadius: 12)
                    .stroke(GymOSColors.primaryPurple, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isPressed ? GymOSColors.primaryPurple.opacity(0.1) : Color.clear)
                    )
            case .minimal:
                RoundedRectangle(cornerRadius: 12)
                    .fill(isPressed ? GymOSColors.primaryPurple.opacity(0.2) : GymOSColors.primaryPurple.opacity(0.1))
            }
        }
    }
    
    private var textColorForVariant: Color {
        switch variant {
        case .filled:
            return .white
        case .bordered, .minimal:
            return GymOSColors.primaryPurple
        }
    }
}

struct WorkoutTimerStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(GymOSColors.purpleGradient)
                    .shadow(
                        color: GymOSColors.primaryPurple.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .foregroundColor(.white)
    }
}

struct RestTimerStyle: ViewModifier {
    let timeRemaining: TimeInterval
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        timeRemaining <= 10 ?
                            LinearGradient(colors: [GymOSColors.dangerRed, GymOSColors.warningOrange], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [GymOSColors.warningOrange, GymOSColors.infoBlue], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(
                        color: timeRemaining <= 10 ? GymOSColors.dangerRed.opacity(0.4) : GymOSColors.warningOrange.opacity(0.3),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
            .foregroundColor(.white)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle(padding: CGFloat = 16, cornerRadius: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding, cornerRadius: cornerRadius))
    }
    
    func glassCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassCardStyle(cornerRadius: cornerRadius))
    }
    
    func workoutTimer() -> some View {
        modifier(WorkoutTimerStyle())
    }
    
    func restTimer(timeRemaining: TimeInterval) -> some View {
        modifier(RestTimerStyle(timeRemaining: timeRemaining))
    }
    
    func gymOSBackground() -> some View {
        background(
            GymOSColors.background(for: UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light)
                .ignoresSafeArea()
        )
    }
}

// MARK: - Custom Buttons
struct PurpleButton: View {
    let title: String
    let action: () -> Void
    let variant: PurpleButtonStyle.Variant
    let icon: String?
    
    init(_ title: String, variant: PurpleButtonStyle.Variant = .filled, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.variant = variant
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
        }
        .buttonStyle(PurpleButtonStyle(variant: variant))
    }
}

// MARK: - Animated Background
struct AnimatedBackground: View {
    @State private var animate = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            GymOSColors.background(for: colorScheme)
            
            // Animated purple orbs
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                GymOSColors.primaryPurple.opacity(0.1),
                                GymOSColors.lightPurple.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(
                        x: animate ? CGFloat.random(in: -100...100) : CGFloat.random(in: -50...50),
                        y: animate ? CGFloat.random(in: -100...100) : CGFloat.random(in: -50...50)
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3...6))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.5),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
        .ignoresSafeArea()
    }
}

// MARK: - Theme Settings View
struct ThemeSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    ForEach(ThemeManager.AppTheme.allCases, id: \.self) { theme in
                        HStack {
                            Text(theme.rawValue)
                            Spacer()
                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark")
                                    .foregroundColor(GymOSColors.primaryPurple)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            themeManager.setTheme(theme)
                        }
                    }
                }
                
                Section("Preview") {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Sample Card")
                                .font(.headline)
                            Spacer()
                            Text("Preview")
                                .foregroundColor(.secondary)
                        }
                        .cardStyle()
                        
                        PurpleButton("Sample Button", variant: .filled) {}
                        PurpleButton("Bordered Button", variant: .bordered) {}
                    }
                }
            }
            .navigationTitle("Theme Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
