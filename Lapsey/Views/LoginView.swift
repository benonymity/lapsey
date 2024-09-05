//
//  LoginView.swift
//  Lapsey
//
//  Created by Benjamin Bassett on 8/31/24.
//

import SwiftUI
import Defaults

struct LoginView: View {
    @State private var token: String = ""
    @State private var isSuccessOverlayPresented: Bool = false
    @State private var isErrorOverlayPresented: Bool = false
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image("Icon")
                .resizable()
                .frame(width: 200, height: 200)
                .cornerRadius(10)
            
            Text("Welcome to Lapsey")
                .font(Font.custom("Georgia", size: 24))
                .fontWeight(.bold)
            
            Text("Login below to get started")
                .font(Font.custom("Georgia", size: 14))
                .foregroundColor(.gray)
            
            TextField("Enter token", text: $token)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: {
                login()
            }) {
                Text("Login")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .successOverlay(isPresented: $isSuccessOverlayPresented, text: { Text("Login successful") })
        .errorOverlay(isPresented: $isErrorOverlayPresented, text: { Text("Invalid token. Please try again.") })
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(authViewModel: AuthViewModel())
    }
}

extension LoginView {
    private func login() {
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        authViewModel.refreshToken = token
//        Defaults[.refreshToken] = token
        
        
        refreshAccessToken() { accessToken in
            if let accessToken = accessToken {
                Defaults[.accessToken] = accessToken
                // Display success message
//                Defaults[.refreshToken] = token
                // authViewModel.refreshToken = token
                isSuccessOverlayPresented = true
                NSLog("Login successful")
            } else {
                // Display error message to the user
                isErrorOverlayPresented = true
                NSLog("Login failed: Invalid token provided.")
            }
        }
    }
}
