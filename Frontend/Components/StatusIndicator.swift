//
//  StatusIndicator.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct StatusIndicator: View {
    let status: VPNStatus
    var size: CGFloat = 16
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                // Outer pulsing ring
                Circle()
                    .stroke(status.color, lineWidth: 2)
                    .frame(width: size * 1.5, height: size * 1.5)
                    .opacity(isPulsing && (status == .connecting || status == .connected) ? 0.3 : 0)
                    .scaleEffect(isPulsing && (status == .connecting || status == .connected) ? 1.5 : 1)
                
                // Core
                Circle()
                    .fill(status.color)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(status.color.opacity(0.8), lineWidth: 1)
                    )
                    .neonGlow(color: status.color, radius: .sm)
            }

            Text(status.displayText.uppercased())
                .techFont(.footnote)
                .foregroundColor(status.color)
                .tracking(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .themedCard(
            cornerRadius: Theme.Radius.pill,
            borderColor: status.color.opacity(0.3),
            borderWidth: 1,
            glowColor: status.color.opacity(0.1),
            glowRadius: 10,
            blurMaterial: .ultraThinMaterial
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        StatusIndicator(status: .disconnected)
        StatusIndicator(status: .connecting)
        StatusIndicator(status: .connected)
        StatusIndicator(status: .reasserting)
    }
    .padding()
    .background(Color.black)
}
