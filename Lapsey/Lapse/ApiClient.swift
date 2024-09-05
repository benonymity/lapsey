//
//  ApiClient.swift
//  Lapsey
//
//  Created by Benjamin Bassett on 8/31/24.
//

import Foundation
import Defaults

enum ApiError: Error {
    case networkError(Error)
    case invalidResponse
    case authenticationFailed
    case jsonParsingError
    case unknownError
    
    var localizedDescription: String {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .authenticationFailed:
            return "Authentication failed"
        case .jsonParsingError:
            return "Failed to parse JSON response"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

class ApiClient {
    private let session = URLSession.shared
    private var accessToken: String
    private let requestURL = URL(string: "https://sync-service.production.journal-api.lapse.app/graphql")!

    init() {
        self.accessToken = ""
        refreshAccessToken() { [weak self] newToken in
            if let newToken = newToken {
                self?.accessToken = newToken
                print("ApiClient initialized with access token")
            } else {
                print("Failed to initialize ApiClient")
            }
        }
    }

    func performRequest(with query: String, completion: @escaping (Result<[String: Any], ApiError>) -> Void) {
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.addValue("\(accessToken)", forHTTPHeaderField: "authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = query.data(using: .utf8)
            print("Request body prepared: \(query)")
        } catch {
            print("Failed to serialize request body: \(error.localizedDescription)")
            completion(.failure(.jsonParsingError))
            return
        }
        
        print("Sending request to \(self.requestURL)")
        session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let data = data else {
                print("No data received in response")
                completion(.failure(.invalidResponse))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                print("Received 401 Unauthorized. Attempting to refresh token.")
                // Token expired, refresh it
                refreshAccessToken() { [weak self] newToken in
                    if let newToken = newToken {
                        print("Token refreshed successfully")
                        self?.accessToken = newToken
                        self?.performRequest(with: query, completion: completion)
                    } else {
                        print("Failed to refresh token")
                        completion(.failure(.authenticationFailed))
                    }
                }
            } else {
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("Request completed successfully with response: \(jsonResponse)")
                        completion(.success(jsonResponse))
                    } else {
                        print("Invalid JSON response")
                        completion(.failure(.invalidResponse))
                    }
                } catch {
                    print("Failed to parse JSON response: \(error.localizedDescription)")
                    completion(.failure(.jsonParsingError))
                }
            }
        }.resume()
    }
}
