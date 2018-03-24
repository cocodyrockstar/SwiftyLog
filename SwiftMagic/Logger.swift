//
//  Logger.swift
//  SwiftMagic
//
//  Created by Zhihui Tang on 2017-10-14.
//


import Foundation


public enum LoggerLevel: Int {
    case info = 1
    case debug
    case warning
    case error
    case none
    
    var name: String {
        switch self {
            case .info: return "💙i"
            case .debug: return "💚d"
            case .warning: return "💛w"
            case .error: return "❤️e"
            case .none: return "N"
        }
    }
}

public enum LoggerOutput: String {
    case debuggerConsole
    case deviceConsole
    case fileOnly
    case debugerConsoleAndFile
    case deviceConsoleAndFile
}


private let fileExtension = "txt"
private let LOG_BUFFER_SIZE = 10

public class Logger: NSObject {
    public static let shared = Logger()
    public var tag: String?
    public var level: LoggerLevel = .none
    public var ouput: LoggerOutput = .debuggerConsole
    public var showThread: Bool = false
    private var data: [String] = []
    
    private let logSubdiretory = FileManager.documentDirectoryURL.appendingPathComponent(fileExtension)
    
    var logUrl: URL? {
        let fileName = "SwiftMagic"
        try? FileManager.default.createDirectory(at: logSubdiretory, withIntermediateDirectories: false)
        let url = logSubdiretory.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
        return url
    }
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        /*
        NSSetUncaughtExceptionHandler { (exception) in
            Logger.shared.save()
        }
         */
    }
    
    @objc private func appMovedToBackground() {
         self.saveAsync()
    }
    
    func saveAsync() {
        guard let url = logUrl else { return }
        
        let lock = NSLock()
        lock.lock()
        defer { lock.unlock() }
        
        DispatchQueue.global(qos: .background).async {
            var stringsData = Data()
            for string in self.data {
                if let stringData = (string + "\n").data(using: String.Encoding.utf8) {
                    stringsData.append(stringData)
                } else {
                    self.e("MutalbeData failed")
                }
            }
            
            do {
                try stringsData.append2File(fileURL: url)
                self.data.removeAll()
            } catch let error as NSError {
                self.e("wrote failed: \(url.absoluteString), \(error.localizedDescription)")
            }
        }
    }
    
    func removeAllAsync() {
        guard let url = logUrl else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    func load() -> [String]? {
        guard let url = logUrl else { return nil }
        guard let strings = try? String(contentsOf: url, encoding: String.Encoding.utf8) else { return nil }

        return strings.components(separatedBy: "\n")
    }

    public func log(_ level: LoggerLevel, message: String, currentTime: Date, fileName: String , functionName: String, lineNumber: Int, thread: Thread) {
        
        guard level.rawValue >= self.level.rawValue else { return }
        
        
        let _fileName = fileName.split(separator: "/")
        let text = "\(level.name)-\(showThread ? thread.description : "")[\(_fileName.last ?? "?")#\(functionName)#\(lineNumber)]\(tag ?? ""): \(message)"
        
        switch self.ouput {
            case .fileOnly:
                addToBuffer(text: "\(currentTime.iso8601) \(text)")
            case .debuggerConsole:
                print("\(currentTime.iso8601) \(text)")
            case .deviceConsole:
                NSLog(text)
            case .debugerConsoleAndFile:
                print("\(currentTime.iso8601) \(text)")
                addToBuffer(text: "\(currentTime.iso8601) \(text)")
            case .deviceConsoleAndFile:
                NSLog(text)
                addToBuffer(text: "\(currentTime.iso8601) \(text)")
        }
    }
    
    private func addToBuffer(text: String) {
        let lock = NSLock()
        lock.lock()
        defer { lock.unlock() }
        
        data.append(text)
        if data.count > LOG_BUFFER_SIZE {
            saveAsync()
        }
    }
    
    public func i(_ message: String, currentTime: Date = Date(), fileName: String = #file, functionName: String = #function, lineNumber: Int = #line, thread: Thread = Thread.current ) {
        log(.info, message: message, currentTime: currentTime, fileName: fileName, functionName: functionName, lineNumber: lineNumber, thread: thread)
    }
    public func d(_ message: String, currentTime: Date = Date(), fileName: String = #file, functionName: String = #function, lineNumber: Int = #line, thread: Thread = Thread.current ) {
        log(.debug, message: message, currentTime: currentTime, fileName: fileName, functionName: functionName, lineNumber: lineNumber, thread: thread)
    }
    public func w(_ message: String, currentTime: Date = Date(), fileName: String = #file, functionName: String = #function, lineNumber: Int = #line, thread: Thread = Thread.current ) {
        log(.warning, message: message, currentTime: currentTime, fileName: fileName, functionName: functionName, lineNumber: lineNumber, thread: thread)
    }
    public func e(_ message: String, currentTime: Date = Date(), fileName: String = #file, functionName: String = #function, lineNumber: Int = #line, thread: Thread = Thread.current ) {
        log(.error, message: message, currentTime: currentTime, fileName: fileName, functionName: functionName, lineNumber: lineNumber, thread: thread)
    }
}

