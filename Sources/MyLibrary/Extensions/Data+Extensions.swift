//
//  Data+extensions.swift
//  image-uploader
//
//  Created by Bd Stock Air-M on 26/7/22.
//

import Foundation

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
