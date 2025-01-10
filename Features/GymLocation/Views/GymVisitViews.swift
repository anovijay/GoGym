//
//  GymVisitViews.swift
//  GoGym
//
//  Created by Anoop Vijayan on 09.01.25.

// GymVisitViews.swift
import SwiftUI

struct GymVisitBadge: View {
    let isActive: Bool
    
    var body: some View {
        Circle()
            .fill(isActive ? Color.green : Color.gray)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(isActive ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
                    .scaleEffect(isActive ? 1.5 : 1.0)
            )
            .animation(.easeInOut, value: isActive)
    }
}

struct GymVisitStats: View {
    let visits: [GymVisit]
    
    private var visitsThisWeek: Int {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return visits.filter { $0.startTime >= oneWeekAgo }.count
    }
    
    private var lastVisit: Date? {
        visits.max(by: { $0.startTime < $1.startTime })?.startTime
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(visitsThisWeek) visits this week")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let last = lastVisit {
                Text("Last visit: \(last.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
