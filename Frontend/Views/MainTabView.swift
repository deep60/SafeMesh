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
        } else {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: Tab.home.rawValue)
                    }
                    .tag(Tab.home)

                ServerListView()
                    .tabItem {
                        Label("Servers", systemImage: Tab.servers.rawValue)
                    }
                    .tag(Tab.servers)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: Tab.settings.rawValue)
                    }
                    .tag(Tab.settings)
            }
            .accentColor(.blue)
        }
    }
}

#Preview {
    MainTabView()
}
