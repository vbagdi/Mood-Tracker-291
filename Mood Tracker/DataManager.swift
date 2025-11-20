import Foundation
import FirebaseFirestore

struct DailyData: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var steps: Int
    var distance: Double
    var sleep: Double
    var flightsClimbed: Int
    var mood: Int
    var userId: String
    var userName: String
    var manualSleepEntry: Bool = false  // ADD THIS
}

class DataManager: ObservableObject {
    @Published var dailyData: [DailyData] = []
    private let db = Firestore.firestore()
    private let userId = UUID().uuidString // Unique ID for this device
    
    init() {
        loadData()
        saveUserIdToDevice()
    }
    
    func saveData(_ data: DailyData) {
        var newData = DailyData(
            id: data.id,
            date: data.date,
            steps: data.steps,
            distance: data.distance,
            sleep: data.sleep,
            flightsClimbed: data.flightsClimbed,  // ADD THIS
            mood: data.mood,
            userId: userId,
            userName: data.userName
        )
        newData.userId = userId
        
        // Save locally
        dailyData.append(newData)
        saveLocally()
        
        // Upload to Firebase
        uploadToFirebase(newData)
    }
    
    
    private func uploadToFirebase(_ data: DailyData) {
        let dataDict: [String: Any] = [
            "id": data.id.uuidString,
            "date": Timestamp(date: data.date),
            "steps": data.steps,
            "distance": data.distance,
            "sleep": data.sleep,
            "flightsClimbed": data.flightsClimbed,
            "mood": data.mood,
            "userId": data.userId,
            "userName": data.userName
        ]
        db.collection("moodData").document(data.id.uuidString).setData(dataDict) { error in
            if let error = error {
                print("Error uploading: \(error)")
            } else {
                print("✅ Data uploaded successfully!")
            }
        }
    }
    
    private func saveLocally() {
        if let encoded = try? JSONEncoder().encode(dailyData) {
            UserDefaults.standard.set(encoded, forKey: "dailyData")
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "dailyData"),
           let decoded = try? JSONDecoder().decode([DailyData].self, from: data) {
            dailyData = decoded
        }
    }
    func fetchAllDataFromFirebase() {
        db.collection("moodData")
            .order(by: "date", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let fetchedData = documents.compactMap { doc -> DailyData? in
                    let data = doc.data()
                    guard let id = data["id"] as? String,
                          let timestamp = data["date"] as? Timestamp,
                          let steps = data["steps"] as? Int,
                          let distance = data["distance"] as? Double,
                          let sleep = data["sleep"] as? Double,
                          let flightsClimbed = data["flightsClimbed"] as? Int,
                          let mood = data["mood"] as? Int,
                          let userId = data["userId"] as? String,
                          let userName = data["userName"] as? String
                    else { return nil }
                    
                    return DailyData(
                        id: UUID(uuidString: id) ?? UUID(),
                        date: timestamp.dateValue(),
                        steps: steps,
                        distance: distance,
                        sleep: sleep,
                        flightsClimbed: flightsClimbed,
                        mood: mood,
                        userId: userId,
                        userName: userName
                    )
                }
                
                DispatchQueue.main.async {
                    self.dailyData = fetchedData
                }
            }
    }
    
    private func saveUserIdToDevice() {
        UserDefaults.standard.set(userId, forKey: "userId")
    }
}
