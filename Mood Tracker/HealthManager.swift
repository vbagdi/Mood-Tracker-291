//
//  HealthManager.swift
//  Mood Tracker
//
//  Created by Vinayak Bagdi on 11/17/25.
//

import Foundation
import HealthKit

class HealthManager: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var steps: Int = 0
    @Published var distance: Double = 0.0
    @Published var sleep: Double = 0.0
    @Published var flightsClimbed: Int = 0

    func requestAuthorization() {
        let types: Set = [
            HKQuantityType(.stepCount),
            HKQuantityType(.distanceWalkingRunning),
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.flightsClimbed)
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
        fetchFlightsClimbed()
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
    
    func fetchFlightsClimbed() {
        let type = HKQuantityType(.flightsClimbed)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            let flights = Int(sum.doubleValue(for: .count()))
            DispatchQueue.main.async {
                self.flightsClimbed = flights
            }
        }
        healthStore.execute(query)
    }
}
