//
//  AlertView.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct AlertView: View {
    let icon: String
    let title: String
    let message: String
    let primaryButton: AlertButton
    let secondaryButton: AlertButton?
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.7)
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        if primaryButton.style == .cancel {
                            isPresented = false
                        }
                    }

                VStack(spacing: 24) {
                    // Icon (Glowing Warning)
                    ZStack {
                        Circle()
                            .strokeBorder(primaryButton.accentColor.opacity(0.3), lineWidth: 4)
                            .frame(width: 80, height: 80)
                            .neonGlow(color: primaryButton.accentColor, radius: .lg)

                        Image(systemName: icon)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(primaryButton.accentColor)
                            .neonGlow(color: primaryButton.accentColor, radius: .sm)
                    }
                    .padding(.bottom, 8)

                    // Content
                    VStack(spacing: 12) {
                        Text(title.uppercased())
                            .techFont(.title3)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .tracking(2)

                        Text(message.uppercased())
                            .techFont(.footnote)
                            .foregroundColor(Theme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal)

                    // Buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            primaryButton.action()
                            isPresented = false
                        }) {
                            Text(primaryButton.title.uppercased())
                                .techFont(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(primaryButton.accentColor.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(primaryButton.accentColor, lineWidth: 2)
                                )
                                .foregroundColor(primaryButton.accentColor)
                                .neonGlow(color: primaryButton.accentColor, radius: .sm)
                        }

                        if let secondaryButton {
                            Button(action: {
                                secondaryButton.action()
                                isPresented = false
                            }) {
                                Text(secondaryButton.title.uppercased())
                                    .techFont(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(32)
                .themedCard(
                    cornerRadius: 16,
                    borderColor: primaryButton.accentColor.opacity(0.5),
                    borderWidth: 2,
                    glowColor: primaryButton.accentColor.opacity(0.3),
                    glowRadius: 20
                )
                .padding(.horizontal, 32)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}


struct AlertButton {
    let title: String
    let action: () -> Void
    let style: Style

    enum Style {
        case primary, cancel, destructive
    }

    var accentColor: Color {
        switch style {
        case .primary: return Theme.Colors.neonCyan
        case .cancel: return Theme.Colors.statusGray
        case .destructive: return Theme.Colors.neonMagenta
        }
    }
}

  #Preview {
      AlertView(
          icon: "exclamationmark.triangle",
          title: "Connection Failed",
          message: "Unable to establish uplink. Check network and try again.",
          primaryButton: AlertButton(title: "Retry Link", action: {}, style: .primary),
          secondaryButton: AlertButton(title: "Abort", action: {}, style: .cancel),
          isPresented: .constant(true)
      )
  }
