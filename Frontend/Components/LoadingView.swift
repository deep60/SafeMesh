//
//  LoadingView.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct LoadingView: View {
    var message: String? = nil
    var showBackground: Bool = true

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            if showBackground {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
            }

            VStack(spacing: 20) {
                // Spinner
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(
                            .linear(duration: 1)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }

                // Message
                if let message {
                    Text(message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

  #Preview {
      LoadingView(message: "Connecting to VPN...")
  }
