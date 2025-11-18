//
//  ChartView.swift
//  Mood Tracker
//
//  Created by Vinayak Bagdi on 11/17/25.
//

import SwiftUI
import Charts

struct ChartView: View {
    @ObservedObject var dataManager: DataManager
    @State private var selectedUser: String = "All"
    
    var filteredData: [DailyData] {
        if selectedUser == "All" {
            return dataManager.dailyData.sorted { $0.date < $1.date }
        } else {
            return dataManager.dailyData
                .filter { $0.userName == selectedUser }
                .sorted { $0.date < $1.date }
        }
    }
    
    var uniqueUsers: [String] {
        let users = Array(Set(dataManager.dailyData.map { $0.userName }))
        return ["All"] + users.sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if filteredData.isEmpty {
                    Text("No data available. Save some entries first!")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    // User filter
                    if uniqueUsers.count > 2 {
                        Picker("Select User", selection: $selectedUser) {
                            ForEach(uniqueUsers, id: \.self) { user in
                                Text(user).tag(user)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding()
                    }
                    
                    // Mood trend chart
                    Chart(filteredData) { entry in
                        LineMark(
                            x: .value("Date", entry.date, unit: .day),
                            y: .value("Mood", entry.mood)
                        )
                        .foregroundStyle(by: .value("User", entry.userName))
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", entry.date, unit: .day),
                            y: .value("Mood", entry.mood)
                        )
                        .foregroundStyle(by: .value("User", entry.userName))
                    }
                    .chartYScale(domain: 0...6)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [1, 2, 3, 4, 5]) { value in
                            AxisGridLine()
                            AxisValueLabel()
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month().day())
                        }
                    }
                    .frame(height: 300)
                    .padding()
                    
                    Text("Mood Trend Over Time")
                        .font(.headline)
                    
                    Text("\(filteredData.count) entries")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .navigationTitle("Mood Trends")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                dataManager.fetchAllDataFromFirebase()
            }
        }
    }
}
