//
//  MainView.swift
//  GoGym
//
//  Created by Anoop Vijayan on 02.01.25.
//
import SwiftUI
import Foundation

struct MainScreen: View {
    @ObservedObject var authState: AuthStateManager
    
    var body: some View {
        Group {
            if authState.isLoggedIn {
                TabView {
                    HomeView(authState: authState)
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }

                    MarkGymLocationView()
                        .tabItem {
                            Label("Mark Gym", systemImage: "mappin.and.ellipse")
                        }

                    Text("Stats") // Will be replaced with StatsView
                        .tabItem {
                            Label("Stats", systemImage: "chart.bar")
                        }

                    SettingsView(authState: authState)
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
            } else {
                AuthView(authState: authState)
            }
        }
        .environmentObject(AppErrorHandler.shared)
    }
}
