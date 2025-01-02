//
//  HomeView.swift
//  GoGym
//
//  Created by Anoop Vijayan on 02.01.25.
//
import SwiftUI

struct HomeView: View {
    @ObservedObject var authState: AuthState

    var body: some View {
        VStack {
            Text("Welcome, \(authState.displayName ?? "User")!")
                .font(.largeTitle)
                .padding()
        }
    }
}

