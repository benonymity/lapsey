//
//  CaptureView.swift
//  Lapsey
//
//  Created by Benjamin Bassett on 8/31/24.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @Binding var selectedImageData: Data?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        SecondaryCameraView(selectedImageData: $selectedImageData, presentationMode: presentationMode)
            .background(Color.black)
            .edgesIgnoringSafeArea(.all)
    }
}

struct SecondaryCameraView: UIViewControllerRepresentable {
    @Binding var selectedImageData: Data?
    var presentationMode: Binding<PresentationMode>
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SecondaryCameraView
        
        init(_ parent: SecondaryCameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                let portraitImage = cropToPortrait(image: uiImage)
                parent.selectedImageData = portraitImage.jpegData(compressionQuality: 0.8)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
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
    }
}
