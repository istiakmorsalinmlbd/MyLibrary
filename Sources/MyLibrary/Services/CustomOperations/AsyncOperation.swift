//
//  AsyncOperation.swift
//  image-uploader
//
//  Created by Bd Stock Air-M on 15/8/22.
//

import Foundation

class AsyncOperation: Operation {
    enum OperationState: String {
        case ready, executing, finished
        
        fileprivate var keyPath: String {
            return "is\(rawValue.capitalized)"
        }
    }
    
    var state = OperationState.ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }
    
    // Concurrent queue for synchronizing access to `state`.
    private let stateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! + "mlbd.imageUploader.state", attributes: .concurrent)
    
    // MARK: - Various `Operation` properties
    override var isReady: Bool {
        return super.isReady && state == .ready
    }
    
    override var isExecuting: Bool {
        return state == .executing
    }
    
    override var isFinished: Bool {
        return state == .finished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override func start() {
        // cancel the operation which has not start yet
        if isCancelled {
            state = .finished
            return
        }
        
        main()
        state = .executing
    }
    
    /// Subclasses must implement this to perform their work and they must not call `super`. The default implementation of this function throws an exception.
    override func main() {
        fatalError("Subclasses must implement `main`.")
    }
    
    public final func finish() {
        if !isFinished && isExecuting { state = .finished }
    }
}
