//
//  PingInducator.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct PingIndicator: View {
    let latency: Int

    private var pingLevel: PingLevel {
        switch latency {
        case 0...50: return .excellent
        case 51...100: return .good
        case 101...200: return .fair
        case 201...300: return .poor
        default: return .veryPoor
        }
    }

    private enum PingLevel {
        case excellent, good, fair, poor, veryPoor

        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .yellow
            case .poor: return .orange
            case .veryPoor: return .red
            }
        }

        var bars: Int {
            switch self {
            case .excellent: return 4
            case .good: return 3
            case .fair: return 2
            case .poor: return 1
            case .veryPoor: return 0
            }
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < pingLevel.bars ? pingLevel.color :
Color.gray.opacity(0.3))
                    .frame(width: 4, height: 12)
            }

            Text("\(latency)ms")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        PingIndicator(latency: 25)
        PingIndicator(latency: 75)
        PingIndicator(latency: 150)
        PingIndicator(latency: 250)
        PingIndicator(latency: 500)
    }
}
