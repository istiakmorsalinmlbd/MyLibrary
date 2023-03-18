//
//  UploadOperation.swift
//  image-uploader
//
//  Created by Bd Stock Air-M on 16/8/22.
//

import Foundation
import UIKit

final class UploadOperation: AsyncOperation {
    let task: URLSessionTask
    
    public init(session: URLSession, request: URLRequest, data: Data) {
        task = session.uploadTask(with: request, from: data)
        super.init()
    }
    
    public init(session: URLSession, request: URLRequest, filePath: URL) {
        task = session.uploadTask(with: request, fromFile: filePath)
        super.init()
    }
    
    override func cancel() {
        super.cancel()
        task.cancel()
        
        // this check is only for onging upload operations
        if isExecuting {
            state = .finished
        }
    }
    
    override func main() {
        task.resume()
    }
}

extension UploadOperation {
    /// Upload complete. Show response came from server.
    public func trackUploadByOperation(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse) {
        defer { self.state = .finished }
        guard !self.isCancelled else { return }
        debugPrint("Operation completed successfully...")
    }
    
    /// Uploading progress.
    public func trackUploadByOperation(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        // do anything with progress data
//        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
    }
    
    /// Download failed.
    public func trackUploadByOperation(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        defer { finish() }
        
        if let error = error {
            debugPrint("Upload Failed in Upload Operation", error.localizedDescription)
        }
    }
    
    public func trackUploadByOperation(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        defer { self.state = .finished }
        guard !self.isCancelled else { return }
        
        debugPrint("Operation Data received successfully...")
    }
}
