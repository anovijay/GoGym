//
//  HomeComponents.swift
//  GoGym
//
//  Created by Anoop Vijayan on 09.01.25.
//
import SwiftUI

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Gym Card Component
struct GymCard: View {
    let gym: GymDetails
    let onLongPress: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(gym.visitsThisWeek > 0 ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                Text(gym.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(gym.visitsThisWeek) visits")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(gym.address)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Label(gym.type.rawValue, systemImage: "dumbbell")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("Radius: \(Int(gym.geofenceRadius))m")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .onLongPressGesture {
            onLongPress()
        }
    }
}

// MARK: - Empty State Component
struct EmptyStateView: View {
    let onAddGym: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No Gyms Added Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your favorite gyms to track your visits")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onAddGym) {
                Label("Add Your First Gym", systemImage: "plus.circle.fill")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - Hero Section Component
struct HomeHeroSection: View {
    let visitCount: Int
    let lastVisit: Date?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatCard(
                    title: "Week Visits",
                    value: "\(visitCount)",
                    icon: "figure.walk"
                )
                StatCard(
                    title: "Last Visit",
                    value: lastVisit?.formatted(.dateTime.weekday().hour()) ?? "No visits",
                    icon: "clock"
                )
            }
            .padding(.horizontal)
        }
    }
}
