//
//  OnboardingView.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "shield.fill",
            title: "SYSTEM SECURED",
            description: "CONNECTION ENCRYPTED WITH MILITARY-GRADE PROTOCOLS. NO UNAUTHORIZED DATA BREACHES DETECTED.",
            color: Theme.Colors.neonCyan
        ),
        OnboardingPage(
            icon: "globe.americas.fill",
            title: "GLOBAL NETWORKS",
            description: "UPLINK ESTABLISHED WITH 50+ REGIONAL NODES. ACCESS TO RESTRICTED DATA GRANTED.",
            color: Theme.Colors.neonMagenta
        ),
        OnboardingPage(
            icon: "bolt.fill",
            title: "HYPER-SPEED ACTIVE",
            description: "OPTIMIZED NETWORK INFRASTRUCTURE ROUTING. LATENCY MINIMIZED TO SUB-MILLISECOND THRESHOLDS.",
            color: Theme.Colors.neonOrange
        ),
        OnboardingPage(
            icon: "eye.slash.fill",
            title: "ZERO TRACE PROTOCOL",
            description: "ALL TELEMETRY DISCARDED INDEFINITELY. YOUR PRESENCE IN THE MESH REMAINS UNDETECTED.",
            color: Theme.Colors.neonLime
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                if currentPage < pages.count - 1 {
                    Button(action: {
                        onComplete()
                    }) {
                        Text("BYPASS")
                            .techFont(.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                            .underline()
                    }
                }
            }
            .padding()

            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Bottom section
            VStack(spacing: 24) {
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Rectangle()
                            .fill(currentPage == index ? pages[currentPage].color : Theme.Colors.secondaryText.opacity(0.3))
                            .frame(width: currentPage == index ? 32 : 12, height: 4)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                            .neonGlow(color: currentPage == index ? pages[currentPage].color : .clear, radius: .sm)
                    }
                }
                .padding(.bottom, 16)

                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    HStack {
                        Text(currentPage < pages.count - 1 ? "NEXT CYCLE" : "INITIALIZE MESH")
                            .techFont(.headline)
                            .tracking(2)

                        if currentPage < pages.count - 1 {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .foregroundColor(Theme.Colors.primaryBackground)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.buttonGradient(color: pages[currentPage].color))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    .neonGlow(color: pages[currentPage].color, radius: .md)
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
        .background(Theme.Colors.primaryBackground)
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .strokeBorder(page.color.opacity(0.3), lineWidth: 4)
                    .frame(width: 180, height: 180)
                    .neonGlow(color: page.color, radius: .lg)

                Circle()
                    .strokeBorder(page.color.opacity(0.6), lineWidth: 2)
                    .frame(width: 140, height: 140)

                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundColor(page.color)
                    .neonGlow(color: page.color, radius: .sm)
            }

            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .techFont(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .tracking(2)

                Text(page.description)
                    .techFont(.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(6)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

#Preview {
    OnboardingView {}
}

