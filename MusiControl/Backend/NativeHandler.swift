//__FILENAME__

import Cocoa

import Socket

protocol NativeHandlerDelegate {
    func connectionClosed()
    func connectionError()
    
    func messageReceived(_ message: JsonMessage)
}

class NativeHandler : Thread {
    enum NativeError : Error {
        case eofError
    }
    
    var delegate: NativeHandlerDelegate? = nil
    
    private let jsonDecoder = JSONDecoder()
    
    private var socket: Socket? = nil
    private var disconnecting = false
    
    private var readData = Data(capacity: 2048)
    
    private func read(bytes: Int) throws -> Data {
        while readData.count < bytes {
            let count = try self.socket?.read(into: &readData)
            if count == 0 {
                // EOF reached
                throw NativeError.eofError
            }
        }
        
        let retData = readData.prefix(bytes)
        readData = readData.dropFirst(bytes)
        return retData
    }
    
    private func readInt32() throws -> Int {
        let data = try read(bytes: 4)
        var target: Int32 = 0
        let _ = withUnsafeMutableBytes(of: &target, { (intPtr: UnsafeMutableRawBufferPointer) in
            data.copyBytes(to: intPtr)
        })
        return Int(target)
    }
    
    private func readString(withLength length: Int) throws -> String? {
        let data = try read(bytes: length)
        return String(data: data, encoding: .utf8)
    }
    
    private func write(int32: Int) throws {
        var data = Data(count: 4)
        data.withUnsafeMutableBytes({ (ptr: UnsafeMutableRawBufferPointer) in
            ptr.storeBytes(of: Int32(int32), as: Int32.self)
        })
        
        try self.socket?.write(from: data)
    }
    
    private func write(string: String) throws {
        guard let stringData = string.data(using: .utf8) else {
            NSLog("Could not encode string as utf8")
            return
        }
        
        try write(int32: stringData.count)
        try self.socket?.write(from: stringData)
    }
    
    func write(data: Data) throws {
        try write(int32: data.count)
        try self.socket?.write(from: data)
    }
    
    private func requestRefresh() throws {
        var obj = [String:Any]()
        obj["type"] = "refresh"
        let json = try! JSONSerialization.data(withJSONObject: obj, options: [])
        try write(data: json)
    }
    
    func disconnect() {
        self.disconnecting = true
        self.socket?.close()
    }
    
    override func main() {
        do {
            let path = BridgeConstants.buildSocketPath()
            NSLog("Connecting to \(path)")
            self.socket = try Socket.create(family: .unix, type: .stream, proto: .unix)
            try self.socket?.connect(to: path)
        } catch {
            DispatchQueue.main.async {
                self.delegate?.connectionError()
                self.delegate?.connectionClosed()
            }
            
            return
        }
        
        do {
            try requestRefresh()
            
            while true {
                // read length
                let length = try readInt32()
                let data = try read(bytes: length)
                
                do {
                    let msg = try self.jsonDecoder.decode(JsonMessage.self, from: data)
                    
                    DispatchQueue.main.async {
                        self.delegate?.messageReceived(msg)
                    }
                } catch let error {
                    NSLog("Error in json data: \(error)")
                    continue
                }
            }
        } catch let error {
            let eofError: Bool
            if case NativeError.eofError = error {
                eofError = true
            } else {
                eofError = false
            }
            
            if eofError || disconnecting {
                // just an eof error
                self.socket?.close()
                DispatchQueue.main.async {
                    self.delegate?.connectionClosed()
                }
                return
            }
            
            self.socket?.close()
            DispatchQueue.main.async {
                NSApp.presentError(error)
                self.delegate?.connectionClosed()
            }
        }
    }
}
