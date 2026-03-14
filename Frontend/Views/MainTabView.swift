//
//  MainTabView.swift
//  SafeMesh
//
//  Created by P Deepanshu on 23/02/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    enum Tab: String, CaseIterable {
        case home = "house.fill"
        case servers = "globe"
        case settings = "gearshape.fill"
    }

    var body: some View {
        if showOnboarding {
            OnboardingView {
                showOnboarding = false
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            }
            .preferredColorScheme(.dark)
        } else {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("System", systemImage: Tab.home.rawValue)
                    }
                    .tag(Tab.home)

                ServerListView()
                    .tabItem {
                        Label("Nodes", systemImage: Tab.servers.rawValue)
                    }
                    .tag(Tab.servers)

                SettingsView()
                    .tabItem {
                        Label("Config", systemImage: Tab.settings.rawValue)
                    }
                    .tag(Tab.settings)
            }
            .accentColor(Theme.Colors.neonCyan)
            .preferredColorScheme(.dark)
            .font(Theme.Typography.caption.font.monospaced())
        }
    }
}

#Preview {
    MainTabView()
}
