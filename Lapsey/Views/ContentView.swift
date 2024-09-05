//
//  ContentView.swift
//  Lapsey
//
//  Created by Benjamin Bassett on 8/31/24.
//

import SwiftUI
import Defaults
import Combine

class AuthViewModel: ObservableObject {
    @Published var refreshToken: String = Defaults[.refreshToken] {
        didSet {
            Defaults[.refreshToken] = refreshToken
            
            // Delay the token validity check by 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.checkTokenValidity()
            }
        }
    }

    init() {
        checkTokenValidity()
    }

    func checkTokenValidity() {
        // Here you can add logic to validate the token
        // For now, we'll assume any non-empty token is valid
        if refreshToken.isEmpty {
            isLoggedIn = false
        } else {
            isLoggedIn = true
        }
    }

    @Published var isLoggedIn: Bool = false
}

struct ContentView: View {
    @StateObject var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                UploadView(authViewModel: authViewModel)
            } else {
                LoginView(authViewModel: authViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
