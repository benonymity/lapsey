//
//  UploadView.swift
//  Lapsey
//
//  Created by Benjamin Bassett on 8/31/24.
//

import SwiftUI
import PhotosUI
import Defaults

struct UploadView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var showingFullScreenImage = false
    @State private var showingCamera = false
    @State private var isUploading = false
    @State private var isSuccessOverlayPresented = false
    @State private var isErrorOverlayPresented = false
    @State private var uploadError: String?
    @State private var successText: Text = Text("Upload successful")
    
    let upload = Upload(apiClient: ApiClient())
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: {
                    logout()
                }) {
                    Text("Log Out")
                        .foregroundColor(.blue)
                }
                .padding(.trailing)
            }
            
            Text("Upload a Photo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let selectedImageData,
               let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 400)
                    .clipShape(Rectangle())
                    .cornerRadius(10)
                    .onTapGesture {
                        showingFullScreenImage = true
                    }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 400)
                    .foregroundColor(.gray)
            }
            
            HStack(spacing: 20) {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()) {
                        Label("Choose Photo", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.bordered)
                
                Button(action: {
                    showingCamera = true
                }) {
                    Label("Take Photo", systemImage: "camera")
                }
                .buttonStyle(.bordered)
            }
            
            Button(action: {
                if let selectedImageData = selectedImageData {
                    uploadImage(imageData: selectedImageData)
                }
            }) {
                Text("Upload")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedImageData == nil || isUploading)
            // .opacity(selectedImageData == nil ? 0.5 : 1.0)
            .padding(.top)
            
            if isUploading {
                ProgressView()
                    .padding()
            }
            
            Button(action: {
                if let url = URL(string: "lapse://") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Lapse")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        let portraitImage = cropToPortrait(image: uiImage)
                        selectedImageData = portraitImage.jpegData(compressionQuality: 0.8)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            if let selectedImageData,
               let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .background(Color.black)
                    .onTapGesture {
                        showingFullScreenImage = false
                    }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(selectedImageData: $selectedImageData)
        }
        .successOverlay(isPresented: $isSuccessOverlayPresented, text: { successText })
        .errorOverlay(isPresented: $isErrorOverlayPresented, text: { Text(uploadError ?? "Upload failed") })
    }
    
    func cropToPortrait(image: UIImage) -> UIImage {
        let shorterSide = min(image.size.width, image.size.height)
        let cropRect = CGRect(x: (image.size.width - shorterSide) / 2,
                              y: (image.size.height - shorterSide) / 2,
                              width: shorterSide,
                              height: shorterSide)
        
        if let cgImage = image.cgImage?.cropping(to: cropRect) {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        }
        return image
    }
    
    func uploadImage(imageData: Data) {
        guard let image = UIImage(data: imageData) else {
            uploadError = "Failed to create image from data"
            isErrorOverlayPresented = true
            return
        }
        
        isUploading = true
        uploadError = nil
        
        upload.uploadPhoto(image: image, developIn: 3) { result in
            DispatchQueue.main.async {
                isUploading = false
                switch result {
                case .success(let fileUUID):
                    print("Upload successful. File UUID: \(fileUUID)")
                    selectedImageData = nil // Clear the selected image after successful upload
                    successText = Text("Upload successful")
                    isSuccessOverlayPresented = true
                case .failure(let error):
                    if let uploadError = error as? UploadError {
                        self.uploadError = uploadError.localizedDescription
                    } else {
                        self.uploadError = "Upload failed: \(error.localizedDescription)"
                    }
                    isErrorOverlayPresented = true
                }
            }
        }
    }

    func logout() {
        authViewModel.refreshToken = ""
        successText = Text("Logout successful")
        isSuccessOverlayPresented = true
    }
}

#Preview {
    UploadView(authViewModel: AuthViewModel()) 
}
