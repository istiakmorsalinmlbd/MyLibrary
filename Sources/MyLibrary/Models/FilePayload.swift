//
//  Media.swift
//  image-uploader
//
//  Created by Bd Stock Air-M on 26/7/22.
//

import Foundation
import UIKit

protocol FileProtocol {
    var fieldName: String { get set }
    var fileName: String { get set }
    var mimeType: String { get set }
    var payload: Data { get set }
    var sourceURL: URL? { get set }
}

struct FilePayload: Decodable & FileProtocol {
    var fieldName: String
    var fileName: String
    var mimeType: String
    var payload: Data
    var sourceURL: URL?
    
    init?(withImage image: UIImage, fieldName: String, fileName: String, mimeType: String = "image/jpeg") {
        self.fieldName = fieldName
        self.fileName = "\(fileName).jpeg"
        self.mimeType = "image/jpeg"

        guard let data = image.jpegData(compressionQuality: 1) else { return nil }
        self.payload = data
    }
}
