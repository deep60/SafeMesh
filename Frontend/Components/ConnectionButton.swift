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
            case .disconnected: return "Connect"
            case .connected: return "Disconnect"
            case .connecting: return "Connecting..."
            case .disconnecting: return "Disconnecting..."
            }
        }
        
        var color: Color {
            switch self {
            case .disconnected: return .blue
            case .connected: return .red
            case .connecting: return .orange
            case .disconnecting: return .orange
            }
        }
        
        var icon: String {
            switch self {
            case .disconnected: return "power"
            case .connected: return "power"
            case .connecting: return "arrow.clockwise"
            case .disconnecting: return "arrow.counterclockwise"
            }
        }
    }
    
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: buttonState.icon)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(buttonState.title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                ZStack {
                    if isConnecting || isDisconnecting {
                        LinearGradient(colors: [buttonState.color, buttonState.color.opacity(0.8)],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing
                        )
                    } else {
                        buttonState.color
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: buttonState.color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isConnecting || isDisconnecting)
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
