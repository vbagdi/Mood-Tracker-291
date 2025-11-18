import Foundation
import FirebaseFirestore

struct DailyData: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var steps: Int
    var distance: Double
    var sleep: Double
    var mood: Int
    var userId: String
    var userName: String
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
    
    private func saveUserIdToDevice() {
        UserDefaults.standard.set(userId, forKey: "userId")
    }
}
