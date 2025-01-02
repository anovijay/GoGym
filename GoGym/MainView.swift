//
//  MainView.swift
//  GoGym
//
//  Created by Anoop Vijayan on 02.01.25.
//
import SwiftUI

struct MainScreen: View {
    @ObservedObject var authState: AuthState

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            Text("Tab 2") // Placeholder for another tab
                .tabItem {
                    Label("Tab 2", systemImage: "square.grid.2x2")
                }

            Text("Tab 3") // Placeholder for another tab
                .tabItem {
                    Label("Tab 3", systemImage: "bell")
                }

            SettingsView(authState: authState)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

