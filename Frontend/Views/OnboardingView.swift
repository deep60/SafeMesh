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
            title: "Your Privacy Matters",
            description: "Secure your internet connection with military-grade encryption and protect your data from prying eyes.",
            color: .blue
        ),
        OnboardingPage(
            icon: "globe.americas.fill",
            title: "Access Any Content",
            description: "Connect to servers in over 50 countries and access content from anywhere in the world.",
            color: .purple
        ),
        OnboardingPage(
            icon: "bolt.fill",
            title: "Lightning Fast",
            description: "Enjoy ultra-fast connection speeds with our optimized network infrastructure.",
            color: .orange
        ),
        OnboardingPage(
            icon: "eye.slash.fill",
            title: "No Logs Policy",
            description: "We never track, collect, or share your browsing data. Your privacy is our priority.",
            color: .green
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        onComplete()
                    }
                    .foregroundColor(.secondary)
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
                        Circle()
                            .fill(currentPage == index ? pages[currentPage].color :
Color.gray.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value:
currentPage)
                    }
                }

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
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(.headline)

                        if currentPage < pages.count - 1 {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [pages[currentPage].color,
pages[currentPage].color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.keyboard)
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
                    .fill(page.color.opacity(0.15))
                    .frame(width: 180, height: 180)

                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundColor(page.color)
            }

            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
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

