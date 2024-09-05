//
//  Authentication.swift
//  Lapsey
//
//  Created by Benjamin Bassett on 8/31/24.
//

import Foundation
import Defaults

func refreshAccessToken(completion: @escaping (String?) -> Void) {
    let url = URL(string: "https://auth.production.journal-api.lapse.app/refresh")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    let body = ["refreshToken": Defaults[.refreshToken]]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            completion(nil)
            return
        }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let accessToken = json["accessToken"] as? String {
            Defaults[.accessToken] = accessToken
            completion(accessToken)
        } else {
            completion(nil)
        }
    }.resume()
}
