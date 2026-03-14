//
//  ServerCard.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct ServerCard: View {
    let server: VPNServer
    var isSelected: Bool = false
    var onTap: (() -> Void)?
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 16) {
                // Server info
                VStack(alignment: .leading, spacing: 4) {
                    Text(server.city.uppercased())
                        .techFont(.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                        .tracking(2)
                    
                    Text(server.country.uppercased())
                        .techFont(.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                // Right Side info
                VStack(alignment: .trailing, spacing: 4) {
                    // Load percentage as a terminal-style display
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.caption2)
                        Text("\(server.loadPercentage)%")
                            .techFont(.caption)
                    }
                    .foregroundColor(loadColor)
                    .neonGlow(color: loadColor, radius: .sm)
                }
                
                // Selection Indicator (Neon Ring)
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Theme.Colors.neonCyan : Theme.Colors.statusGray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .neonGlow(color: isSelected ? Theme.Colors.neonCyan : .clear, radius: .md)
                    
                    if isSelected {
                        Circle()
                            .fill(Theme.Colors.neonCyan)
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.leading, 8)
            }
            .padding(16)
            .themedCard(
                borderColor: isSelected ? Theme.Colors.neonCyan : Theme.Colors.statusGray.opacity(0.3),
                borderWidth: isSelected ? 2 : 1,
                glowColor: isSelected ? Theme.Colors.neonCyan : .clear,
                glowRadius: isSelected ? 8 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var loadColor: Color {
        switch server.loadPercentage {
        case 0..<50: return Theme.Colors.neonLime
        case 50..<80: return Theme.Colors.neonOrange
        default: return Theme.Colors.neonMagenta
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ServerCard(server: .mock, isSelected: true)
        ServerCard(server: .mock, isSelected: false)
    }
    .padding()
}
