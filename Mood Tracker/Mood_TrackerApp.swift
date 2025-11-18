//
//  Mood_TrackerApp.swift
//  Mood Tracker
//
//  Created by Vinayak Bagdi on 11/17/25.
//

import SwiftUI
import FirebaseCore
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Register background task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.dsc291.MoodTracker.dailySave", using: nil) { task in
            self.handleDailySave(task: task as! BGProcessingTask)
        }
        
        return true
    }
    
    func handleDailySave(task: BGProcessingTask) {
        scheduleNextDailySave()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform the save
        let healthManager = HealthManager()
        healthManager.fetchTodayData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            let userName = UserDefaults.standard.string(forKey: "userName") ?? ""
            let selectedMood = UserDefaults.standard.integer(forKey: "lastMood")
            
            let data = DailyData(
                date: Date(),
                steps: healthManager.steps,
                distance: healthManager.distance,
                sleep: healthManager.sleep,
                mood: selectedMood == 0 ? 3 : selectedMood,
                userId: "",
                userName: userName
            )
            
            DataManager().saveData(data)
            UserDefaults.standard.set(Date(), forKey: "lastAutoSave")
            print("✅ Background save completed")
            
            task.setTaskCompleted(success: true)
        }
    }
    
    func scheduleNextDailySave() {
        let request = BGProcessingTaskRequest(identifier: "com.dsc291.MoodTracker.dailySave")
        
        // Schedule for 11:59 PM today or tomorrow
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        components.minute = 59
        
        if let scheduledDate = Calendar.current.date(from: components) {
            let nextDate = scheduledDate > Date() ? scheduledDate : Calendar.current.date(byAdding: .day, value: 1, to: scheduledDate)!
            request.earliestBeginDate = nextDate
        }
        
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Scheduled next background save")
        } catch {
            print("❌ Could not schedule: \(error)")
        }
    }
}

@main
struct Mood_TrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    delegate.scheduleNextDailySave()
                }
        }
    }
}
