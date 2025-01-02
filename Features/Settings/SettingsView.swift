//
//  SettingsView.swift
//  GoGym
//
//  Created by Anoop Vijayan on 02.01.25.
//
import SwiftUI

struct SettingsView: View {
    @ObservedObject var authState: AuthState

    var body: some View {
        VStack {
            if authState.isLoggedIn {
                Button(action: {
                    authState.signOut()
                }) {
                    Text("Log Out")
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            } else {
                AuthView(authState: authState)
            }
        }
        .padding()
    }
}
