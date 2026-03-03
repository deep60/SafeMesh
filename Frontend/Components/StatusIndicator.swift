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

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status.color)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(status.color.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: status.color, radius: 4)

            Text(status.displayText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(status.color.opacity(0.15))
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusIndicator(status: .disconnected)
        StatusIndicator(status: .connecting)
        StatusIndicator(status: .connected)
        StatusIndicator(status: .reasserting)
    }
}
