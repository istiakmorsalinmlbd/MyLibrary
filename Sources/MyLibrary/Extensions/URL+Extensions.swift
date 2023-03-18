//
//  URL+Extensions.swift
//  image-uploader
//
//  Created by Bd Stock Air-M on 17/12/22.
//

import Foundation
import MobileCoreServices
import UniformTypeIdentifiers

extension URL {
    
    @available(iOS 14.0, *)
    var mimeType: String {
        let pathExtension = self.pathExtension
        if let type = UTType(filenameExtension: pathExtension) {
            if let mimetype = type.preferredMIMEType {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }

    @available(iOS 14.0, *)
    var containsImage: Bool {
        let mimeType = self.mimeType
        if let type = UTType(mimeType: mimeType) {
            return type.conforms(to: .image)
        }
        return false
    }

    @available(iOS 14.0, *)
    var containsAudio: Bool {
        let mimeType = self.mimeType
        if let type = UTType(mimeType: mimeType) {
            return type.conforms(to: .audio)
        }
        return false
    }

    @available(iOS 14.0, *)
    var containsMovie: Bool {
        let mimeType = self.mimeType
        if let type = UTType(mimeType: mimeType) {
            return type.conforms(to: .movie)   // ex. .mp4-movies
        }
        return false
    }
    
    @available(iOS 14.0, *)
    var containsVideo: Bool {
        let mimeType = self.mimeType
        if let type = UTType(mimeType: mimeType) {
            return type.conforms(to: .video)
        }
        return false
    }
}
