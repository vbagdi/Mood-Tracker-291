//
//  ContentView.swift
//  Mood Tracker
//
//  Created by Vinayak Bagdi on 11/17/25.
//

import SwiftUI
import HealthKit
import UserNotifications

class SleepEntryManager: ObservableObject {
    @Published var pendingSleepHours: Double = 0.0
    @Published var hasPendingSleep: Bool = false
    
    func savePendingSleep(hours: Double) {
        pendingSleepHours = hours
        hasPendingSleep = true
        let today = getTodayKey()
        UserDefaults.standard.set(hours, forKey: "pendingSleep_\(today)")
        UserDefaults.standard.set(true, forKey: "hasPendingSleep_\(today)")
    }
    
    func loadPendingSleep() {
        let today = getTodayKey()
        pendingSleepHours = UserDefaults.standard.double(forKey: "pendingSleep_\(today)")
        hasPendingSleep = UserDefaults.standard.bool(forKey: "hasPendingSleep_\(today)")
    }
    
    func clearPendingSleep() {
        let today = getTodayKey()
        UserDefaults.standard.removeObject(forKey: "pendingSleep_\(today)")
        UserDefaults.standard.removeObject(forKey: "hasPendingSleep_\(today)")
        pendingSleepHours = 0.0
        hasPendingSleep = false
    }
    
    private func getTodayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var performSave: (() -> Void)?
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        performSave?()
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

struct ContentView: View {
    @StateObject private var healthManager = HealthManager()
    @StateObject private var dataManager = DataManager()
    @StateObject private var sleepManager = SleepEntryManager()
    
    @State private var selectedMood: Int = 3
    @State private var showingHistory = false
    @State private var showingChart = false
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var manualSleepHours: String = ""
    
    private let notificationDelegate = NotificationDelegate()
    
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
                    
                    // Sleep entry section
                    if !sleepManager.hasPendingSleep {
                        VStack {
                            Text("Last Night's Sleep")
                                .font(.headline)
                            
                            HStack {
                                TextField("Hours slept", text: $manualSleepHours)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 100)
                                
                                Text("hours")
                                
                                Button("Save Sleep") {
                                    if let hours = Double(manualSleepHours) {
                                        sleepManager.savePendingSleep(hours: hours)
                                        manualSleepHours = ""
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding()
                    } else {
                        HStack {
                            Text("✅ Sleep logged: \(String(format: "%.1f", sleepManager.pendingSleepHours)) hours")
                                .foregroundColor(.green)
                            
                            Button("Edit") {
                                sleepManager.clearPendingSleep()
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)
                        }
                        .padding()
                    }
                    
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
                        Text("Sleep (last night): \(String(format: "%.1f", sleepManager.hasPendingSleep ? sleepManager.pendingSleepHours : healthManager.sleep)) hours")
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
                sleepManager.loadPendingSleep()
                requestNotificationPermission()
                scheduleNotifications()
                
                UNUserNotificationCenter.current().delegate = notificationDelegate
                notificationDelegate.performSave = saveTodayData
            }
            .onChange(of: userName) { newValue in
                UserDefaults.standard.set(newValue, forKey: "userName")
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            }
        }
    }
    
    func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        // Morning notification at 8 AM for sleep entry
        let morningContent = UNMutableNotificationContent()
        morningContent.title = "Good Morning!"
        morningContent.body = "How many hours did you sleep last night?"
        morningContent.sound = .default
        
        var morningComponents = DateComponents()
        morningComponents.hour = 8
        morningComponents.minute = 0
        
        let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morningComponents, repeats: true)
        let morningRequest = UNNotificationRequest(identifier: "morningSleep", content: morningContent, trigger: morningTrigger)
        
        // Evening notification at 9 PM for daily save
        let eveningContent = UNMutableNotificationContent()
        eveningContent.title = "Evening Check-In"
        eveningContent.body = "Time to save your daily mood and activity!"
        eveningContent.sound = .default
        
        var eveningComponents = DateComponents()
        eveningComponents.hour = 21
        eveningComponents.minute = 0
        
        let eveningTrigger = UNCalendarNotificationTrigger(dateMatching: eveningComponents, repeats: true)
        let eveningRequest = UNNotificationRequest(identifier: "eveningSave", content: eveningContent, trigger: eveningTrigger)
        
        center.add(morningRequest) { error in
            if let error = error {
                print("❌ Error scheduling morning notification: \(error)")
            } else {
                print("✅ Morning notification scheduled for 8 AM")
            }
        }
        
        center.add(eveningRequest) { error in
            if let error = error {
                print("❌ Error scheduling evening notification: \(error)")
            } else {
                print("✅ Evening notification scheduled for 9 PM")
            }
        }
    }
    
    func saveTodayData() {
        // Use pending sleep if available, otherwise use HealthKit sleep
        let sleepToSave = sleepManager.hasPendingSleep ? sleepManager.pendingSleepHours : healthManager.sleep
        
        let data = DailyData(
            date: Date(),
            steps: healthManager.steps,
            distance: healthManager.distance,
            sleep: sleepToSave,
            flightsClimbed: healthManager.flightsClimbed,
            mood: selectedMood,
            userId: "",
            userName: userName,
            manualSleepEntry: sleepManager.hasPendingSleep
        )
        dataManager.saveData(data)
        
        // Clear pending sleep after saving
        sleepManager.clearPendingSleep()
        
        print("✅ Saved entry with sleep: \(sleepToSave) hours")
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
