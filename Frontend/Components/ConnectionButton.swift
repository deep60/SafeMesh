//
//  ConnectionButton.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct ConnectionButton: View {
    var isConnected: Bool = false
    var isConnecting: Bool = false
    var isDisconnecting: Bool = false
    var onTap: () -> Void = {}
    
    @State private var pulseState: Bool = false
    
    private var buttonState: ButtonState {
        if isConnecting { return .connecting }
        if isDisconnecting { return .disconnecting }
        if isConnected { return .connected }
        return .disconnected
    }
    
    private enum ButtonState {
        case disconnected, connected, connecting, disconnecting
        
        var title: String {
            switch self {
            case .disconnected: return "I N I T I A T E"
            case .connected: return "T E R M I N A T E"
            case .connecting: return "A C Q U I R I N G . . ."
            case .disconnecting: return "S E V E R I N G . . ."
            }
        }
        
        var color: Color {
            switch self {
            case .disconnected: return Theme.Colors.neonCyan
            case .connected: return Theme.Colors.neonMagenta
            case .connecting: return Theme.Colors.neonOrange
            case .disconnecting: return Theme.Colors.neonOrange
            }
        }
        
        var icon: String {
            switch self {
            case .disconnected: return "bolt.fill"
            case .connected: return "bolt.slash.fill"
            case .connecting: return "satellite.fill"
            case .disconnecting: return "bolt.horizontal.fill"
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                if isConnecting || isDisconnecting {
                    Image(systemName: buttonState.icon)
                        .font(.title2.weight(.bold))
                        .symbolEffect(.pulse, options: .repeating)
                } else {
                    Image(systemName: buttonState.icon)
                        .font(.title2.weight(.bold))
                }
                
                Text(buttonState.title)
                    .techFont(.headline)
            }
            .foregroundColor(buttonState.color)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                ZStack {
                    // Glass material base
                    RoundedRectangle(cornerRadius: Theme.Radius.xl)
                        .fill(.ultraThinMaterial)
                    
                    // Dark inner tint
                    RoundedRectangle(cornerRadius: Theme.Radius.xl)
                        .fill(Theme.Colors.secondaryBackground.opacity(0.8))
                    
                    // Animated pulsing gradient for active states
                    if isConnecting || isDisconnecting {
                        RoundedRectangle(cornerRadius: Theme.Radius.xl)
                            .fill(
                                LinearGradient(
                                    colors: [buttonState.color.opacity(0.2), buttonState.color.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(pulseState ? 1.0 : 0.4)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.xl)
                    .strokeBorder(buttonState.color.opacity(isConnecting || isDisconnecting ? 0.8 : 0.4), lineWidth: 2)
            )
            // Outer plasma glow
            .neonGlow(color: buttonState.color, radius: (isConnecting || isDisconnecting) && pulseState ? .lg : .md)
            .scaleEffect((isConnecting || isDisconnecting) && pulseState ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseState)
        }
        .disabled(isConnecting || isDisconnecting)
        .onAppear {
            pulseState = true
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ConnectionButton(isConnected: false)
        ConnectionButton(isConnected: true)
        ConnectionButton(isConnecting: true)
    }
    .padding()
}
