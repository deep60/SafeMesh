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
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        if primaryButton.style == .cancel {
                            isPresented = false
                        }
                    }

                VStack(spacing: 20) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(primaryButton.accentColor.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: icon)
                            .font(.system(size: 36))
                            .foregroundColor(primaryButton.accentColor)
                    }

                    // Content
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .multilineTextAlignment(.center)

                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    // Buttons
                    VStack(spacing: 12) {
                        Button(primaryButton.title) {
                            primaryButton.action()
                            isPresented = false
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(primaryButton.accentColor)

                        if let secondaryButton {
                            Button(secondaryButton.title) {
                                secondaryButton.action()
                                isPresented = false
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 30)
                )
                .padding(.horizontal, 40)
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
        case .primary: return .blue
        case .cancel: return .gray
        case .destructive: return .red
        }
    }
}

  #Preview {
      AlertView(
          icon: "exclamationmark.triangle",
          title: "Connection Failed",
          message: "Unable to connect to the VPN server. Please check your internet connection and try again.",
          primaryButton: AlertButton(title: "Retry", action: {}, style: .primary),
          secondaryButton: AlertButton(title: "Cancel", action: {}, style: .cancel),
          isPresented: .constant(true)
      )
  }
