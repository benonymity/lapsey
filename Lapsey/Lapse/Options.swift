//
//  Options.swift
//  Lapsey
//
//  Created by Benjamin Bassett on 8/31/24.
//

import Foundation

let iosVersions = ["16", "16.0.1", "16.0.2", "16.0.3", "16.1", "16.1.1", "16.1.2", "16.2", "16.3", "16.3.1", "16.4",
                   "16.4.1", "16.5", "16.5.1", "16.6", "16.6.1", "16.7", "16.7.1", "16.7.2"]

let devices = ["iPhone10,4", "iPhone10,5", "iPhone10,6", "iPhone11,2", "iPhone11,4", "iPhone11,6", "iPhone11,8",
               "iPhone12,1", "iPhone12,3", "iPhone12,5", "iPhone12,8", "iPhone13,1", "iPhone13,2", "iPhone13,3",
               "iPhone13,4", "iPhone14,2", "iPhone14,3", "iPhone14,4", "iPhone14,5", "iPhone14,6", "iPhone14,7",
               "iPhone14,8", "iPhone15,2", "iPhone15,3", "iPhone15,4", "iPhone15,5", "iPhone16,1", "iPhone16,2"]

class BaseOptions {
    var headers = [String: String]()

    init(kwargs: [String: String]) {
        kwargs.forEach { key, value in
            headers["HEADER_\(key)"] = value
        }
        if headers["HEADER_x_device_id"] == nil {
            headers["HEADER_x_device_id"] = UUID().uuidString
        }
    }

    func formatHeader(key: String) -> String {
        var key = key.replacingOccurrences(of: "HEADER_", with: "")
        key = key.replacingOccurrences(of: "_", with: "-")
        key = key.replacingOccurrences(of: "--", with: "_")
        return key
    }

    func toHeaders(operationName: String, authorizationToken: String) -> [String: String] {
        let attrs = headers.keys
        var keyValuePair = [String: String]()
        attrs.forEach { attr in
            keyValuePair[formatHeader(key: attr)] = headers[attr] ?? ""
        }

        let xEmbPath = "/graphql/\(operationName)"
        keyValuePair["x-apollo-operation-name"] = operationName
        keyValuePair["x-emb-path"] = xEmbPath
        keyValuePair["authorization"] = authorizationToken

        return keyValuePair
    }
}

class Options: BaseOptions {
    init(xIosVersionNumber: String? = nil,
         xDeviceName: String? = nil,
         userAgent: String? = nil,
         xAppVersionNumber: String = "3.21.1",
         xTimezone: String = "America/New_York",
         xDeviceId: String? = nil,
         xAppBuildNumber: Int = 21975,
         apollographqlClientName: String = "com.lapse.journal-apollo-ios",
         apollographqlClientVersion: String? = nil,
         acceptLanguage: String = "en-US,en;q=0.9") {
        var kwargs = [String: String]()
        kwargs["x_ios_version_number"] = xIosVersionNumber ?? iosVersions.randomElement()!
        kwargs["x_device_name"] = xDeviceName ?? devices.randomElement()!
        kwargs["user_agent"] = userAgent ?? "Lapse/\(xAppVersionNumber)/\(xAppBuildNumber) iOS"
        kwargs["x_app_version_number"] = xAppVersionNumber
        kwargs["x_timezone"] = xTimezone
        kwargs["x_device_id"] = xDeviceId ?? UUID().uuidString
        kwargs["x_app_build_number"] = String(xAppBuildNumber)
        kwargs["apollographql_client_name"] = apollographqlClientName
        kwargs["apollographql_client_version"] = apollographqlClientVersion ?? "\(xAppVersionNumber)-\(xAppBuildNumber)"
        kwargs["accept_language"] = acceptLanguage
        kwargs["accept"] = "*/*"
        kwargs["content_type"] = "application/json"
        kwargs["accept_encoding"] = "gzip, deflate, br"
        kwargs["x_apollo_operation_type"] = "query"

        super.init(kwargs: kwargs)
    }
}
