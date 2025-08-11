// BackendService.swift
import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Backend Service
final class BackendService: ObservableObject {
    static let shared = BackendService()
    
    private let db = Firestore.firestore()
    private var listeners: [String: ListenerRegistration] = [:]
    
    private init() {}
    
    // MARK: - Authentication
    func sendOTP(phoneNumber: String) async throws -> String {
        // For demo purposes, generate a 6-digit code
        // In production, this would integrate with Twilio
        let otp = String(format: "%06d", Int.random(in: 100000...999999))
        
        // Store OTP in Firestore for verification
        try await db.collection("otp_codes").document(phoneNumber).setData([
            "code": otp,
            "createdAt": FieldValue.serverTimestamp(),
            "expiresAt": FieldValue.serverTimestamp()
        ])
        
        print("🔑 OTP for \(phoneNumber): \(otp)")
        return otp
    }
    
    func verifyOTP(phoneNumber: String, code: String) async throws -> User {
        let document = try await db.collection("otp_codes").document(phoneNumber).getDocument()
        
        guard let data = document.data(),
              let storedCode = data["code"] as? String,
              storedCode == code else {
            throw BackendError.invalidOTP
        }
        
        // Create or get user
        let user = try await createOrGetUser(phoneNumber: phoneNumber)
        
        // Clean up OTP
        try await db.collection("otp_codes").document(phoneNumber).delete()
        
        return user
    }
    
    private func createOrGetUser(phoneNumber: String) async throws -> User {
        let userDoc = db.collection("users").document(phoneNumber)
        
        do {
            let document = try await userDoc.getDocument()
            
            if document.exists {
                // User exists, return existing data
                let data = document.data() ?? [:]
                return User(
                    id: document.documentID,
                    name: data["name"] as? String ?? "User",
                    email: data["email"] as? String ?? "",
                    phoneNumber: phoneNumber,
                    profileImageURL: data["profileImageURL"] as? String,
                    linkedBankToken: data["linkedBankToken"] as? String,
                    stripeCustomerId: data["stripeCustomerId"] as? String
                )
            } else {
                // Create new user
                let newUser = User(
                    id: phoneNumber,
                    name: "User",
                    email: "",
                    phoneNumber: phoneNumber,
                    profileImageURL: nil,
                    linkedBankToken: nil,
                    stripeCustomerId: nil
                )
                
                try await userDoc.setData([
                    "name": newUser.name,
                    "email": newUser.email,
                    "phoneNumber": newUser.phoneNumber,
                    "createdAt": FieldValue.serverTimestamp()
                ])
                
                return newUser
            }
        } catch {
            throw BackendError.userCreationFailed
        }
    }
    
    // MARK: - Event Management
    func createEvent(_ event: BillEvent) async throws -> BillEvent {
        var eventData = event.toDictionary()
        eventData["createdAt"] = FieldValue.serverTimestamp()
        eventData["updatedAt"] = FieldValue.serverTimestamp()
        
        let docRef = try await db.collection("events").addDocument(data: eventData)
        
        var updatedEvent = event
        updatedEvent.id = docRef.documentID
        
        // Generate event code
        let eventCode = generateEventCode()
        try await db.collection("event_codes").document(eventCode).setData([
            "eventId": docRef.documentID,
            "createdAt": FieldValue.serverTimestamp()
        ])
        
        return updatedEvent
    }
    
    func joinEvent(code: String) async throws -> BillEvent {
        let codeDoc = try await db.collection("event_codes").document(code).getDocument()
        
        guard let data = codeDoc.data(),
              let eventId = data["eventId"] as? String else {
            throw BackendError.invalidEventCode
        }
        
        let eventDoc = try await db.collection("events").document(eventId).getDocument()
        
        guard let eventData = eventDoc.data() else {
            throw BackendError.eventNotFound
        }
        
        return BillEvent.fromDictionary(eventData, id: eventId)
    }
    
    func updateEvent(_ event: BillEvent) async throws {
        var eventData = event.toDictionary()
        eventData["updatedAt"] = FieldValue.serverTimestamp()
        
        try await db.collection("events").document(event.id).setData(eventData, merge: true)
    }
    
    func fetchRecentEvents(for userId: String) async throws -> [BillEvent] {
        let snapshot = try await db.collection("events")
            .whereField("creatorId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 10)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            BillEvent.fromDictionary(document.data(), id: document.documentID)
        }
    }
    
    // MARK: - Real-time Updates
    func listenToEvent(_ eventId: String, completion: @escaping (BillEvent?) -> Void) {
        let listener = db.collection("events").document(eventId)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot,
                      let data = document.data() else {
                    completion(nil)
                    return
                }
                
                let event = BillEvent.fromDictionary(data, id: document.documentID)
                completion(event)
            }
        
        listeners[eventId] = listener
    }
    
    func stopListeningToEvent(_ eventId: String) {
        listeners[eventId]?.remove()
        listeners.removeValue(forKey: eventId)
    }
    
    // MARK: - Helper Methods
    private func generateEventCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
}

// MARK: - Backend Errors
enum BackendError: Error, LocalizedError {
    case invalidOTP
    case userCreationFailed
    case invalidEventCode
    case eventNotFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidOTP:
            return "Invalid verification code"
        case .userCreationFailed:
            return "Failed to create user account"
        case .invalidEventCode:
            return "Invalid event code"
        case .eventNotFound:
            return "Event not found"
        case .networkError:
            return "Network connection error"
        }
    }
}

// MARK: - Model Extensions
extension BillEvent {
    func toDictionary() -> [String: Any] {
        return [
            "creatorId": creatorId,
            "eventName": eventName,
            "restaurantName": restaurantName,
            "totalAmount": totalAmount,
            "tax": tax,
            "tipPercentage": tipPercentage,
            "receiptImageURL": receiptImageURL ?? "",
            "items": items.map { $0.toDictionary() },
            "participants": participants.map { $0.toDictionary() },
            "status": status.rawValue,
            "virtualCardId": virtualCardId ?? ""
        ]
    }
    
    static func fromDictionary(_ data: [String: Any], id: String) -> BillEvent {
        let items = (data["items"] as? [[String: Any]] ?? []).compactMap { BillItem.fromDictionary($0) }
        let participants = (data["participants"] as? [[String: Any]] ?? []).compactMap { EventParticipant.fromDictionary($0) }
        
        return BillEvent(
            id: id,
            creatorId: data["creatorId"] as? String ?? "",
            eventName: data["eventName"] as? String ?? "",
            restaurantName: data["restaurantName"] as? String ?? "",
            totalAmount: data["totalAmount"] as? Double ?? 0,
            tax: data["tax"] as? Double ?? 0,
            tipPercentage: data["tipPercentage"] as? Double ?? 0,
            receiptImageURL: data["receiptImageURL"] as? String,
            items: items,
            participants: participants,
            status: EventStatus(rawValue: data["status"] as? String ?? "draft") ?? .draft,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            virtualCardId: data["virtualCardId"] as? String
        )
    }
}

extension BillItem {
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "price": price,
            "quantity": quantity,
            "claimedBy": claimedBy,
            "isSharedByTable": isSharedByTable,
            "isSelected": isSelected
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> BillItem? {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String else {
            return nil
        }
        
        return BillItem(
            id: id,
            name: name,
            price: data["price"] as? Double ?? 0,
            quantity: data["quantity"] as? Int ?? 1,
            claimedBy: data["claimedBy"] as? [String] ?? [],
            isSharedByTable: data["isSharedByTable"] as? Bool ?? false,
            isSelected: data["isSelected"] as? Bool ?? false
        )
    }
}

extension EventParticipant {
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "userName": userName,
            "subtotal": subtotal,
            "taxAmount": taxAmount,
            "tipAmount": tipAmount,
            "totalOwed": totalOwed,
            "paymentStatus": paymentStatus.rawValue,
            "paymentIntentId": paymentIntentId ?? ""
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> EventParticipant? {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let userName = data["userName"] as? String else {
            return nil
        }
        
        return EventParticipant(
            id: id,
            userId: userId,
            userName: userName,
            subtotal: data["subtotal"] as? Double ?? 0,
            taxAmount: data["taxAmount"] as? Double ?? 0,
            tipAmount: data["tipAmount"] as? Double ?? 0,
            totalOwed: data["totalOwed"] as? Double ?? 0,
            paymentStatus: PaymentStatus(rawValue: data["paymentStatus"] as? String ?? "pending") ?? .pending,
            paymentIntentId: data["paymentIntentId"] as? String
        )
    }
}
