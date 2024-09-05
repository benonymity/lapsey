//
//  Utilities.swift
//  Lapsey
//
//  Created by Benjamin Bassett on 8/31/24.
//

import Foundation
import Defaults

extension Defaults.Keys {
    static let refreshToken = Key<String>("refreshToken", default:"")
    static let accessToken = Key<String>("accessToken", default:"")
    static let flash = Key<Bool>("flash", default: false)
    static let autoUpload = Key<Bool>("autoUpload", default: false)
}
