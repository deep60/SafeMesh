//
//  Theme.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

// MARK: - Theme
enum Theme {
    // MARK: - Colors
    enum Colors {
        // Status Colors
        static let statusBlue = Color.blue
        static let statusGreen = Color.green
        static let statusOrange = Color.orange
        static let statusRed = Color.red
        static let statusYellow = Color.yellow
        static let statusGray = Color.gray

        // Background Colors
        static let primaryBackground = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)

        // Text Colors
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary

        // Gradient Colors
        static let gradientStart = Color.blue
        static let gradientEnd = Color.purple

        // Connection Status
        static let connected = Color.green
        static let disconnected = Color.gray
        static let connecting = Color.orange
        static let disconnecting = Color.orange
        static let reconnecting = Color.yellow
        static let error = Color.red

        // Accents
        static let accent = Color.accentColor
        static let success = Color.green
        static let warning = Color.orange
        static let danger = Color.red
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
        static let sm: CGFloat = 10
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let pill: CGFloat = 100
    }

    // MARK: - Shadows
    enum Shadow {
        case sm
        case md
        case lg

        var radius: CGFloat {
            switch self {
            case .sm: return 4
            case .md: return 8
            case .lg: return 16
            }
        }

        var opacity: Double {
            switch self {
            case .sm: return 0.05
            case .md: return 0.1
            case .lg: return 0.15
            }
        }

        var color: Color {
            Color.black.opacity(opacity)
        }
    }

    // MARK: - Typography
    enum Typography {
        case largeTitle
        case title
        case title2
        case title3
        case headline
        case subheadline
        case body
        case callout
        case footnote
        case caption
        case caption2

        var font: Font {
            switch self {
            case .largeTitle: return .largeTitle
            case .title: return .title
            case .title2: return .title2
            case .title3: return .title3
            case .headline: return .headline
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
                colors: [Colors.gradientStart.opacity(0.3), Colors.gradientEnd.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Colors.statusGray.opacity(0.1), Colors.statusGray.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func buttonGradient(color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - View Extensions for Theme
extension View {
    func themedCard(
        cornerRadius: CGFloat = Theme.Radius.md,
        shadow: Theme.Shadow = .sm
    ) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Theme.Colors.primaryBackground)
                    .shadow(color: shadow.color, radius: shadow.radius)
            )
    }

    func themedShadow(_ shadow: Theme.Shadow = .sm) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius)
    }
}