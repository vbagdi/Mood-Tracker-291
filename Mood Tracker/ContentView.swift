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
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("Mood Tracker")
            .sheet(isPresented: $showingHistory) {
                HistoryView(dataManager: dataManager)
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
                    Text("Sleep: \(String(format: "%.1f", entry.sleep))h | Distance: \(String(format: "%.1f", entry.distance))km")
                        .font(.caption)
                }
            }
            .navigationTitle("History")
        }
    }
}

class HealthManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var steps: Int = 0
    @Published var distance: Double = 0.0
    @Published var sleep: Double = 0.0
    
    func requestAuthorization() {
        let types: Set = [
            HKQuantityType(.stepCount),
            HKQuantityType(.distanceWalkingRunning),
            HKCategoryType(.sleepAnalysis)
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: types) { success, error in
            if success {
                print("HealthKit authorized")
            }
        }
    }
    
    func fetchTodayData() {
        fetchSteps()
        fetchDistance()
        fetchSleep()
    }
    
    func fetchSteps() {
        let type = HKQuantityType(.stepCount)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            let steps = Int(sum.doubleValue(for: .count()))
            DispatchQueue.main.async {
                self.steps = steps
            }
        }
        healthStore.execute(query)
    }
    
    func fetchDistance() {
        let type = HKQuantityType(.distanceWalkingRunning)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            let distance = sum.doubleValue(for: .meterUnit(with: .kilo))
            DispatchQueue.main.async {
                self.distance = distance
            }
        }
        healthStore.execute(query)
    }
    
    func fetchSleep() {
        let type = HKCategoryType(.sleepAnalysis)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            guard let samples = samples as? [HKCategorySample] else { return }
            
            let totalSleep = samples.reduce(0.0) { total, sample in
                total + sample.endDate.timeIntervalSince(sample.startDate)
            }
            
            DispatchQueue.main.async {
                self.sleep = totalSleep / 3600
            }
        }
        healthStore.execute(query)
    }
}
