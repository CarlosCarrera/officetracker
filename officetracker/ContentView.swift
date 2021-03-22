//
//  ContentView.swift
//  officetracker
//
//  Created by Carlos Carrera on 22/03/21.
//  Copyright © 2021 Carlos Carrera. All rights reserved.
//

import SwiftUI
import CoreWLAN

struct ContentView: View {
    var presenter: Presenter = Presenter()
    let myGray: Color = Color(red: 0.5, green: 0.5, blue: 0.5)
    
    var body: some View {
        VStack {
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
        .onAppear {
            presenter.getStatus()
        }
        
    }
}

class Presenter {
    @Published var status: OfficeStatus = .notConnected
    let repository: NetworkRepository = NetworkRepository()
    func getStatus() {
        let wifiClient = CWWiFiClient.shared()
        if let ssid = wifiClient.interface()?.ssid() {
            if ssid == "Apiumhub" {
                status = .inside
            } else {
                status = .outside
            }
        } else {
            status = .notConnected
        }
        repository.recordStatus(status: status, id: wifiClient.interface()?.hardwareAddress() ?? "unknown")
    }
}

import FirebaseFirestore

class NetworkRepository {
    let db = Firestore.firestore()

    func recordStatus(status: OfficeStatus, id: String) {
        var ref: DocumentReference? = nil
        ref = db.collection("userStatus").addDocument(data: [
            "id": id,
            "value": status.rawValue
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
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
        ContentView()
    }
}
