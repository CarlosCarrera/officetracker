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
    @ObservedObject var presenter: Service
    let myGray: Color = Color(red: 0.5, green: 0.5, blue: 0.5)
    @State var textFieldText: String = ""

    @ObservedObject var userData: UserData

    init(userData: UserData) {
        self.userData = userData
        presenter = Service(userData: userData)
    }
    
    var body: some View {
        let binding = Binding<String> { () -> String in
            self.textFieldText
        } set: {
            self.textFieldText = $0
            userData.username = $0
        }

        VStack {
            HStack {
                TextField("Your name", text: binding)
            }
            .padding(10)
            .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(myGray, lineWidth: 1)
                    )

            HStack {
                
                Text("")
                    .padding()
                    .background(presenter.status.statusColor)
                    .clipShape(Circle())
                
                Text(presenter.status.statusDescription)
                Spacer()
            }
            .padding(10)
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

    var userData: UserData

    init(userData: UserData) {
        self.userData = userData
        getStatus()
        Timer.scheduledTimer(withTimeInterval: resendInterval, repeats: true) { [weak self] _ in
            self?.getStatus()
        }
    }

    func getStatus() {
        let wifiClient = CWWiFiClient.shared()
        if let ssid = wifiClient.interface()?.ssid() {
            if ssid == ["vodafone0160", "apiumhub"].randomElement()! {
                status = .inside
            } else {
                status = .outside
            }
        } else {
            status = .notConnected
        }
        repository.recordStatus(status: status, id: wifiClient.interface()?.hardwareAddress() ?? "unknown", username: userData.username)
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
