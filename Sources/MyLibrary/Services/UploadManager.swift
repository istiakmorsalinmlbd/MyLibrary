//
//  UploadManager.swift
//  image-uploader
//
//  Created by Bd Stock Air-M on 26/7/22.
//

import Foundation
import UIKit

protocol UploadManagerDelegate: NSObject {
    func uploadingProgress(_ percent: Double, id: Int)
    func uploadSucceeded(_ message: String, id: Int, data: Data)
    func uploadWithError(_ error: Error?, id: Int)
}

class UploadManager: NSObject {
    
    static let shared = UploadManager()
    
    // MARK: - properties
    public var savedCompletionHandler: (() -> Void)?
    private(set) var numberOfOperations: Int = 0
    private(set) var numberOfCompletedOperations: Int = 0
    public let backgroundIdentifier = "com.mlbd.imageUploader"
    private static let queueName = "uploadQueue"
    
    public static var maxOperationCount = 1
    public var targetUrlString = "" //"https://dev.thebeats.app/api/users/update"
    public var authorizationToken = ""
    
    private var boundary: String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    private var targetUrl: URL? {
        return URL(string: UploadManager.shared.targetUrlString)
    }
    
    private var authorization: String {
        return "Bearer " + UploadManager.shared.authorizationToken
    }
    
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = queueName
        queue.maxConcurrentOperationCount = maxOperationCount
        return queue
    }()
    
    public lazy var urlSession: URLSession = {
//        let config = URLSessionConfiguration.default
        let config = URLSessionConfiguration.background(withIdentifier: backgroundIdentifier)
        config.isDiscretionary = false
        config.networkServiceType = .background
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    // track operations
    private var operations = [Int: UploadOperation]()
    
    /// Track the download process
    public weak var delegate : UploadManagerDelegate?
    
    // MARK: - methods
    
    // only supports foreground upload
    public func queueUpload(request: URLRequest, dataBody: Data) -> UploadOperation? {
        let operation = UploadOperation(session: urlSession, request: request, data: dataBody)
        operations[operation.task.taskIdentifier] = operation
        queue.addOperation(operation)
        self.numberOfOperations += 1
        return operation
    }
    
    // support both foreground and background upload
    public func queueUpload(request: URLRequest, filePath: URL) -> UploadOperation? {
        let operation = UploadOperation(session: urlSession, request: request, filePath: filePath)
        operations[operation.task.taskIdentifier] = operation
        queue.addOperation(operation)
        self.numberOfOperations += 1
        return operation
    }
    
    private func cancelAllOperations() {
        queue.cancelAllOperations()
    }
    
    public func cancleOperation(identifier: Int) {
        let operation = operations[identifier]
        operation?.cancel()
    }
    
    @available(iOS 14.0, *)
    public func uploadImage(image: UIImage, file: FilePayload, parameters: [String: String]?) -> Int {

        // upload request with data only works in foreground
//        guard let result = createRequestAndBody(withParameters: parameters, files: [file]) else { return -1 }
//        let operation = queueUpload(request: result.request, dataBody: result.body)
        
        guard let result = requestAndPath(for: file, image: image, parameters: parameters) else { return -1 }
        let operation = queueUpload(request: result.request, filePath: result.filePath)
        return operation?.task.taskIdentifier ?? -1
    }
    
    @available(iOS 14.0, *)
    private func requestAndPath(for filePayload: FilePayload, image: UIImage, parameters: [String: String]?) -> (request: URLRequest, filePath: URL)? {
        
        // Create an empty file and append parameters and file content to it
        let uuid = UUID().uuidString
        let directoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let fileURL = directoryURL.appendingPathComponent(uuid)
        let filePath = fileURL.path
        FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
        let file = FileHandle(forWritingAtPath: filePath)!
        
        var modifiedFilePayload = filePayload
        modifiedFilePayload.mimeType = fileURL.mimeType // change mimeType to newly created file's mimeType
        
        guard let requestAndBody = createRequestAndBody(withParameters: parameters, files: [modifiedFilePayload]) else {
            return nil
        }
        
        file.write(requestAndBody.body)
        file.closeFile()
        
        return (requestAndBody.request, fileURL)
    }
    
    private func createRequestAndBody<T: Decodable & FileProtocol>(withParameters parameters: [String: String]?, files: [T]?) -> (request: URLRequest, body: Data)? {
        
        let lineBreak = "\r\n"
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        
        guard let url = self.targetUrl else {
            debugPrint("Please set server url endpoint")
            return nil
        }

        if let parameters = parameters {
            for (key, value) in parameters {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
                body.append("\(value)\r\n")
            }
        }
        
        if let files = files {
            for file in files {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\(lineBreak)")
                body.append("Content-Type: \(file.mimeType + lineBreak + lineBreak)")
                body.append(file.payload)
                body.append(lineBreak)
            }
        }

        body.append("--\(boundary)--\(lineBreak)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")  // adjust if your response is not JSON
        request.addValue(self.authorization, forHTTPHeaderField: "Authorization")
//        request.addValue("ios", forHTTPHeaderField: "device")
        
        // do not forget to set the content-length for uploadTask. sometimes with it uploadTask not working properly
        request.setValue(String(body.count), forHTTPHeaderField: "Content-Length")
        
        return (request, body)
    }
    
    private func checkCompletenessOfOperations() {
        if self.numberOfOperations == self.numberOfCompletedOperations {
            self.numberOfOperations = 0
            self.numberOfCompletedOperations = 0
        }
    }
}

// MARK: - URLSessionDataDelegate
extension UploadManager: URLSessionDataDelegate {
    
    // https://stackoverflow.com/a/40379595
    // This method will not be called for background upload tasks (which cannot be converted to download tasks).
    // Response received: Provides a reference to the response object which can be used for example for checking the http status code.
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        debugPrint("didReceive response")
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else { return }
        completionHandler(URLSession.ResponseDisposition.allow)
    }
    
    // Data received: Provides the data returned from the server.
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        debugPrint("Data Received")
        operations[dataTask.taskIdentifier]?.trackUploadByOperation(session, dataTask: dataTask, didReceive: data)
        
        self.numberOfCompletedOperations += 1
        checkCompletenessOfOperations()
        
        DispatchQueue.main.async {
            self.delegate?.uploadSucceeded("upload successful", id: dataTask.taskIdentifier, data: data)
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            debugPrint("\(json)")
            // do something with json
        } catch {
            debugPrint("Can't parse json: \(error.localizedDescription)")
        }
    }
}

// MARK: - URLSessionTaskDelegate
extension UploadManager: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        operations[task.taskIdentifier]?.trackUploadByOperation(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
        debugPrint("Progress in upload manager: \(progress)")
        DispatchQueue.main.async {
            self.delegate?.uploadingProgress(progress, id: task.taskIdentifier)
        }
    }
    
    // Error received: Handler for server-side error
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            debugPrint("Upload Failed ", error.localizedDescription)
            operations[task.taskIdentifier]?.trackUploadByOperation(session, task: task, didCompleteWithError: error)
            
            self.numberOfCompletedOperations += 1
            checkCompletenessOfOperations()
            
            DispatchQueue.main.async {
                self.delegate?.uploadWithError(error, id: task.taskIdentifier)
            }
        }
    }
}

// MARK: - URLSessionDelegate
extension UploadManager: URLSessionDelegate {
    // saved completion handler to let OS know you're done processing the background request completion
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.savedCompletionHandler?()
            self.savedCompletionHandler = nil
        }
    }
}
