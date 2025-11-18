//
//  ContentView.swift
//  Mood Tracker
//
//  Created by Vinayak Bagdi on 11/17/25.
//

// finished everything

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var healthManager = HealthManager()
    @StateObject private var dataManager = DataManager()
    
    @State private var selectedMood: Int = 3
    @State private var showingHistory = false
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State private var showingChart = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Daily Mood Check-In")
                        .font(.title)
                        .bold()
                    
                    // Name input
                    TextField("Enter your name", text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                    
                    // Mood selector
                    VStack {
                        Text("How are you feeling? (1-5)")
                            .font(.headline)
                        
                        HStack(spacing: 15) {
                            ForEach(1...5, id: \.self) { mood in
                                Button(action: {
                                    selectedMood = mood
                                    UserDefaults.standard.set(mood, forKey: "lastMood")
                                }) {
                                    Text("\(mood)")
                                        .font(.title)
                                        .frame(width: 50, height: 50)
                                        .background(selectedMood == mood ? Color.blue : Color.gray.opacity(0.3))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding()
                    
                    // Today's data
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Today's Data:")
                            .font(.headline)
                        Text("Steps: \(healthManager.steps)")
                        Text("Distance: \(String(format: "%.2f", healthManager.distance)) km")
                        Text("Sleep: \(String(format: "%.1f", healthManager.sleep)) hours")
                        Text("Flights Climbed: \(healthManager.flightsClimbed)")

                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Action buttons
                    VStack(spacing: 15) {
                        Button("Refresh Data") {
                            healthManager.fetchTodayData()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Save Today's Entry") {
                            saveTodayData()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("View History") {
                            showingHistory = true
                        }
                        .buttonStyle(.bordered)
                        
                        Button("View Trends Chart") {
                            showingChart = true
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Mood Tracker")
            .sheet(isPresented: $showingHistory) {
                HistoryView(dataManager: dataManager)
            }
            .sheet(isPresented: $showingChart) {
                ChartView(dataManager: dataManager)
            }
            .onAppear {
                healthManager.requestAuthorization()
                healthManager.fetchTodayData()
            }
            .onChange(of: userName) { newValue in
                UserDefaults.standard.set(newValue, forKey: "userName")
            }
            .onReceive(timer) { _ in
                checkAndSaveDaily()
            }
        }
    }
    
    func saveTodayData() {
        let data = DailyData(
            date: Date(),
            steps: healthManager.steps,
            distance: healthManager.distance,
            sleep: healthManager.sleep,
            flightsClimbed: healthManager.flightsClimbed,
            mood: selectedMood,
            userId: "",
            userName: userName
        )
        dataManager.saveData(data)
    }
    
    func checkAndSaveDaily() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        // Check if it's 11:59 PM
        if hour == 23 && minute == 59 {
            let lastSaveDate = UserDefaults.standard.object(forKey: "lastAutoSave") as? Date
            let today = calendar.startOfDay(for: now)
            
            // Only save once per day
            if lastSaveDate == nil || !calendar.isDate(lastSaveDate!, inSameDayAs: today) {
                healthManager.fetchTodayData()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    let data = DailyData(
                        date: Date(),
                        steps: healthManager.steps,
                        distance: healthManager.distance,
                        sleep: healthManager.sleep,
                        flightsClimbed: healthManager.flightsClimbed,
                        mood: selectedMood,
                        userId: "",
                        userName: userName
                    )
                    dataManager.saveData(data)
                    UserDefaults.standard.set(Date(), forKey: "lastAutoSave")
                    print("✅ Auto-saved daily data at 11:59 PM")
                }
            }
        }
    }
}

struct HistoryView: View {
    @ObservedObject var dataManager: DataManager
    
    var body: some View {
        NavigationView {
            List(dataManager.dailyData.reversed()) { entry in
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.date, style: .date)
                        .font(.headline)
                    Text("\(entry.userName) - Mood: \(entry.mood)/5 | Steps: \(entry.steps)")
                    Text("Sleep: \(String(format: "%.1f", entry.sleep))h | Distance: \(String(format: "%.1f", entry.distance))km | Flights: \(entry.flightsClimbed)")
                        .font(.caption)
                }
            }
            .navigationTitle("History")
        }
    }
}

