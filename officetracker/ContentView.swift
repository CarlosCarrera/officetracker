//
//  ContentView.swift
//  officetracker
//
//  Created by Carlos Carrera on 22/03/21.
//  Copyright © 2021 Carlos Carrera. All rights reserved.
//

import SwiftUI
import CoreWLAN

class UserData: ObservableObject {
    @Published var username: String = ""
}

struct ContentView: View {
    @ObservedObject var service: Service
    let myGray: Color = Color(red: 0.5, green: 0.5, blue: 0.5)
    @State var textFieldText: String = ""
    
    @ObservedObject var userData: UserData

    @State var editMode: Bool = true
    
    init(userData: UserData) {
        self.userData = userData
        service = Service(userData: userData)
    }
    
    var body: some View {
        VStack {
            HStack {
                if editMode {
                    TextField("Your name", text: $textFieldText)
                } else {
                    Text(textFieldText)
                    Spacer()
                }

                Button(editMode ? "Set" : "Edit") {
                    if editMode {
                        userData.username = textFieldText
                        service.triggerStatus()
                    }

                    editMode.toggle()
                }
            }
            .padding(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(myGray, lineWidth: 1)
            )
            
            HStack {
                Circle()
                    .fill(service.status.statusColor)
                    .frame(width: 20)
                
                Text(service.status.statusDescription)
                Spacer()
            }
            .frame(height: 50)
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(myGray, lineWidth: 1)
            )
        }
        .padding(10)
    }
}

class Service: ObservableObject {
    @Published var status: OfficeStatus = .notConnected
    let repository: NetworkRepository = NetworkRepository()
    let resendInterval = 5.0 // 1 min
    let officeSsid = "vodafone0160"
    
    let wifiClient = CWWiFiClient.shared()
    var userData: UserData
    
    init(userData: UserData) {
        self.userData = userData
        try? wifiClient.startMonitoringEvent(with: CWEventType.ssidDidChange)
        wifiClient.delegate = self
        triggerStatus()
    }

    func triggerStatus() {
        let ssid = self.wifiClient.interface()?.ssid() ?? "unknown"
        sendStatus(ssid: ssid)
    }

    private func sendStatus(ssid: String) {
        if ssid == self.officeSsid {
            self.status = .inside
        } else {
            self.status = .outside
        }
        self.repository.recordStatus(status: self.status,
                                     id: self.wifiClient.interface()?.hardwareAddress() ?? "unknown",
                                     username: self.userData.username.isEmpty ? "Unknown" : self.userData.username)
    }
}

extension Service: CWEventDelegate {
    func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        DispatchQueue.main.async {
            guard let ssid = self.wifiClient.interface(withName: interfaceName)?.ssid() else  {
                self.status = .notConnected
                return
            }
            self.sendStatus(ssid: ssid)
        }
    }
}

import FirebaseFirestore

class NetworkRepository {
    let db = Firestore.firestore()
    
    func recordStatus(status: OfficeStatus, id: String, username: String? = nil) {
        db.collection("userStatus").document("\(id)").setData([
            "value": status.rawValue,
            "timestamp": String(format: "%.0f", Date().timeIntervalSince1970),
            "username": username ?? ""
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(id)")
            }
        }
    }
}

enum OfficeStatus: Int {
    case notConnected = 0
    case inside = 1
    case outside = 2
    
    var statusDescription: String {
        switch self {
        case .notConnected:
            return "Not connected to wifi"
        case .inside:
            return "You are in the office"
        case .outside:
            return "Outside the office"
        }
    }
    
    var statusColor: Color {
        switch self {
        case .notConnected:
            return .red
        case .inside:
            return .green
        case .outside:
            return .gray
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(userData: UserData())
    }
}
