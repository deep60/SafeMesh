//
//  Theme.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

// MARK: - Theme (Alien/Cyberpunk Redesign)
enum Theme {
    // MARK: - Colors
    enum Colors {
        // Deep Space Backgrounds
        static let primaryBackground = Color(red: 0.03, green: 0.02, blue: 0.06)
        static let secondaryBackground = Color(red: 0.08, green: 0.07, blue: 0.12)
        static let tertiaryBackground = Color(red: 0.12, green: 0.10, blue: 0.18)

        // Neon Accents
        static let neonCyan = Color(red: 0.0, green: 1.0, blue: 1.0)
        static let neonMagenta = Color(red: 1.0, green: 0.0, blue: 0.8)
        static let neonLime = Color(red: 0.2, green: 1.0, blue: 0.2)
        static let neonOrange = Color(red: 1.0, green: 0.4, blue: 0.0)
        static let neonBlue = Color(red: 0.2, green: 0.4, blue: 1.0)

        // Status Colors
        static let statusBlue = neonBlue
        static let statusGreen = neonLime
        static let statusOrange = neonOrange
        static let statusRed = neonMagenta
        static let statusYellow = Color(red: 1.0, green: 1.0, blue: 0.0)
        static let statusGray = Color(white: 0.3)

        // Text Colors
        static let primaryText = Color.white
        static let secondaryText = Color(white: 0.7)

        // Gradient Colors
        static let gradientStart = neonCyan
        static let gradientEnd = neonBlue

        // Connection Status
        static let connected = neonCyan
        static let disconnected = statusGray
        static let connecting = neonMagenta
        static let disconnecting = neonOrange
        static let reconnecting = statusYellow
        static let error = neonMagenta

        // Semantic Accents
        static let accent = neonCyan
        static let success = neonLime
        static let warning = neonOrange
        static let danger = neonMagenta
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Corner Radius
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 18
        static let xl: CGFloat = 24
        static let pill: CGFloat = .infinity
    }

    // MARK: - Shadows (Neon Glows)
    enum Shadow {
        case sm, md, lg, intense

        var radius: CGFloat {
            switch self {
            case .sm: return 6
            case .md: return 12
            case .lg: return 20
            case .intense: return 30
            }
        }

        var opacity: Double {
            switch self {
            case .sm: return 0.3
            case .md: return 0.5
            case .lg: return 0.7
            case .intense: return 1.0
            }
        }
    }

    // MARK: - Typography
    enum Typography {
        case largeTitle, title, title2, title3
        case headline, subheadline, body
        case callout, footnote, caption, caption2

        var font: Font {
            switch self {
            case .largeTitle: return .largeTitle.weight(.bold)
            case .title: return .title.weight(.bold)
            case .title2: return .title2.weight(.bold)
            case .title3: return .title3.weight(.semibold)
            case .headline: return .headline.weight(.semibold)
            case .subheadline: return .subheadline
            case .body: return .body
            case .callout: return .callout
            case .footnote: return .footnote
            case .caption: return .caption
            case .caption2: return .caption2
            }
        }
    }

    // MARK: - Gradients
    static func primaryGradient(isConnected: Bool = false) -> LinearGradient {
        if isConnected {
            return LinearGradient(
                colors: [Colors.neonCyan.opacity(0.15), Colors.neonBlue.opacity(0.05), Colors.primaryBackground],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [Colors.secondaryBackground, Colors.primaryBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func buttonGradient(color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.9), color.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - View Extensions for Theme
extension View {
    func themedCard(
        cornerRadius: CGFloat = Theme.Radius.lg,
        borderColor: Color = .clear,
        borderWidth: CGFloat = 0,
        glowColor: Color = .clear,
        glowRadius: CGFloat = 0,
        blurMaterial: Material? = .ultraThin
    ) -> some View {
        self
            .background(
                ZStack {
                    if let material = blurMaterial {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(material)
                    }
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Theme.Colors.secondaryBackground.opacity(blurMaterial == nil ? 1 : 0.6))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: glowColor.opacity(0.5), radius: glowRadius)
    }

    func neonGlow(color: Color, radius: Theme.Shadow = .md) -> some View {
        self.shadow(color: color.opacity(radius.opacity), radius: radius.radius)
    }
    
    // Applies the mono-spaced alien tech font style
    func techFont(_ type: Theme.Typography = .body) -> some View {
        self
            .font(type.font)
            .monospaced()
    }
}