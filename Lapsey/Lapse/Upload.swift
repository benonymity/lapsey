//
//  Upload.swift
//  Lapsey
//
//  Created by Benjamin Bassett on 8/31/24.
//

import Foundation
import UIKit

enum UploadError: Error {
    case imageConversionFailed
    case uploadURLMissing
    case awsUploadFailed
    case createMediaFailed
    case unexpectedResponse
    case apiError(ApiError)
    
    var localizedDescription: String {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to data"
        case .uploadURLMissing:
            return "Failed to get upload URL from server"
        case .awsUploadFailed:
            return "Failed to upload image to AWS"
        case .createMediaFailed:
            return "Failed to create media in Lapse"
        case .unexpectedResponse:
            return "Received unexpected response from server"
        case .apiError(let apiError):
            return apiError.localizedDescription
        }
    }
}

class Upload {
    private let apiClient: ApiClient
    
    init(apiClient: ApiClient) {
        self.apiClient = apiClient
        print("Upload instance initialized")
    }
    
    func uploadPhoto(image: UIImage, developIn: Int, completion: @escaping (Result<String, Error>) -> Void) {
        print("Starting photo upload process")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to JPEG data")
            completion(.failure(UploadError.imageConversionFailed))
            return
        }
        
        let fileUUID = UUID().uuidString
        let takenAt = ISO8601DateFormatter().string(from: Date())
        print("Generated fileUUID: \(fileUUID), takenAt: \(takenAt)")
        
        // First, get the upload URL
        let uploadURLQuery = """
        {
          "operationName": "ImageUploadURLGraphQLQuery",
          "query": "query ImageUploadURLGraphQLQuery($filename: String!) { imageUploadURL(filename: $filename) }",
          "variables": {
            "filename": "\(fileUUID)/filtered_0.heic"
          }
        }
        """
        
        print("Requesting upload URL")
        apiClient.performRequest(with: uploadURLQuery) { [weak self] result in
            switch result {
            case .success(let response):
                if let errors = response["errors"] as? [[String: Any]] {
                    let errorMessage = errors.first?["message"] as? String ?? "Unknown error occurred"
                    print("API request failed with error: \(errorMessage)")
                    completion(.failure(UploadError.apiError(.unknownError)))
                    return
                }
                
                guard let data = response["data"] as? [String: Any],
                      let uploadURL = data["imageUploadURL"] as? String else {
                    print("Failed to extract upload URL from response")
                    completion(.failure(UploadError.uploadURLMissing))
                    return
                }
                print("Received upload URL: \(uploadURL)")
                
                self?.uploadImageToAWS(imageData: imageData, uploadURL: uploadURL) { result in
                    switch result {
                    case .success:
                        print("Successfully uploaded image to AWS")
                        self?.createMedia(fileUUID: fileUUID, takenAt: takenAt, developIn: developIn, completion: completion)
                    case .failure(let error):
                        print("Failed to upload image to AWS: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            case .failure(let apiError):
                print("API request for upload URL failed: \(apiError.localizedDescription)")
                completion(.failure(UploadError.apiError(apiError)))
            }
        }
    }
    
    private func uploadImageToAWS(imageData: Data, uploadURL: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("Starting AWS upload")
        var request = URLRequest(url: URL(string: uploadURL)!)
        request.httpMethod = "PUT"
        request.setValue("Lapse/20651 CFNetwork/1408.0.4 Darwin/22.5.0", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.uploadTask(with: request, from: imageData) { _, response, error in
            if let error = error {
                print("AWS upload failed with error: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("AWS upload completed successfully")
                completion(.success(()))
            } else {
                print("AWS upload failed with unexpected response")
                completion(.failure(UploadError.awsUploadFailed))
            }
        }.resume()
    }
    
    private func createMedia(fileUUID: String, takenAt: String, developIn: Int, completion: @escaping (Result<String, Error>) -> Void) {
        print("Creating media entry")
        let createMediaQuery = """
        {
          "operationName": "CreateMediaGraphQLMutation",
          "query": "mutation CreateMediaGraphQLMutation($input: CreateMediaInput!) { createMedia(input: $input) { __typename success } }",
          "variables": {
            "input": {
              "content": [
                {
                  "filtered": "\(fileUUID)/filtered_0",
                  "metadata": {
                    "colorTemperature": 6000,
                    "exposureValue": 9,
                    "didFlash": false
                  }
                }
              ],
              "developsAt": {
                "isoString": "\(ISO8601DateFormatter().string(from: Date().addingTimeInterval(5)))"
              },
              "faces": [],
              "mediaId": "\(fileUUID)",
              "takenAt": {
                "isoString": "\(ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: TimeInterval(takenAt) ?? 0)))"
              },
              "timezone": "\(TimeZone.current.identifier)"
            }
          }
        }
        """
        
        apiClient.performRequest(with: createMediaQuery) { result in
            switch result {
            case .success(let response):
                if let data = response["data"] as? [String: Any],
                   let createMedia = data["createMedia"] as? [String: Any],
                   let success = createMedia["success"] as? Bool,
                   success {
                    print("Media creation successful for fileUUID: \(fileUUID)")
                    completion(.success(fileUUID))
                } else {
                    print("Failed to create media entry: \(response)")
                    completion(.failure(UploadError.createMediaFailed))
                }
            case .failure(let apiError):
                print("API request for media creation failed: \(apiError.localizedDescription)")
                completion(.failure(UploadError.apiError(apiError)))
            }
        }
    }
}
