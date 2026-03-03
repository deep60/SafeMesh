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
                //Country flag
                //CountryFlag()
                
                //Server info
                VStack(alignment: .leading, spacing: 4) {
                    Text(server.city)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(server.country)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Right Side info
                VStack(alignment: .trailing, spacing: 4) {
                    //PingIndicator(latency: server.latency)
                    
                    if server.loadPercentage > 70 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text("\(server.loadPercentage)")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .gray.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 12) {
        ServerCard(server: .mock, isSelected: true)
        ServerCard(server: .mock, isSelected: false)
    }
    .padding()
}
