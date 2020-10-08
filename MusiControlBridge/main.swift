//__FILENAME__

import Foundation
import Socket

enum NativeError : Error {
    case eofError
}

func dataFrom(int32: Int) -> Data {
    var data = Data(count: 4)
    data.withUnsafeMutableBytes({ (ptr: UnsafeMutableRawBufferPointer) in
        ptr.storeBytes(of: Int32(int32), as: Int32.self)
    })
    
    return data
}

class ConnectionHandler {
    var socket: Socket? = nil
    private var readData = Data(capacity: 2048)
    
    init(withSocket socket: Socket) {
        self.socket = socket
    }
    
    private func readSocket(bytes: Int) throws -> Data {
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
    
    private func readSocketInt32() throws -> Int {
        let data = try readSocket(bytes: 4)
        var target: Int32 = 0
        let _ = withUnsafeMutableBytes(of: &target, { (intPtr: UnsafeMutableRawBufferPointer) in
            data.copyBytes(to: intPtr)
        })
        return Int(target)
    }
    
    private func readSocketString(withLength length: Int) throws -> String? {
        let data = try readSocket(bytes: length)
        return String(data: data, encoding: .utf8)
    }
    
    private func writeSocket(int32: Int) throws {
        let data = dataFrom(int32: int32)
        try self.socket?.write(from: data)
    }
    
    func writeSocket(string: String) throws {
        guard let stringData = string.data(using: .utf8) else {
            NSLog("Could not encode string as utf8")
            return
        }
        
        try writeSocket(int32: stringData.count)
        try self.socket?.write(from: stringData)
    }
    
    private func writeNative(int32: Int) {
        let data = dataFrom(int32: int32)
        FileHandle.standardOutput.write(data)
    }
    
    private func writeNative(string: String) {
        guard let stringData = string.data(using: .utf8) else {
            NSLog("Could not encode string as utf8")
            return
        }
        
        writeNative(int32: stringData.count)
        FileHandle.standardOutput.write(stringData)
    }
    
    func handleConnection() {
        // copy socket to stdout
        do {
            while true {
                // read length
                let length = try readSocketInt32()
                guard let data = try readSocketString(withLength: length) else {
                    NSLog("Invalid value for string")
                    continue
                }
                
                // send it back
                writeNative(string: data)
            }
            
        } catch let error {
            NSLog("Error while stream reading: \(error)")
        }
        
        self.socket?.close()
        try? FileHandle.standardOutput.synchronize()
    }
}

class MusiControlBridge : NSObject {
    private var unixSocket: Socket? = nil
    private var handler: ConnectionHandler? = nil
    private var readData = Data(capacity: 2048)
    private var end = false
    
    private func readNative(bytes: Int) throws -> Data {
        while readData.count < bytes {
            let data = FileHandle.standardInput.readData(ofLength: bytes - readData.count)
            if data.isEmpty {
                // we are eof
                throw NativeError.eofError
            }
            
            readData.append(data)
        }
        
        let retData = readData.prefix(bytes)
        readData = readData.dropFirst(bytes)
        return retData
    }
    
    private func readNativeInt32() throws -> Int {
        let data = try readNative(bytes: 4)
        var target: Int32 = 0
        let _ = withUnsafeMutableBytes(of: &target, { (intPtr: UnsafeMutableRawBufferPointer) in
            data.copyBytes(to: intPtr)
        })
        return Int(target)
    }
    
    private func readNativeString(withLength length: Int) throws -> String? {
        let data = try readNative(bytes: length)
        return String(data: data, encoding: .utf8)
    }
    
    private func handleNative() {
        DispatchQueue.global(qos: .default).async {
            // copy stdin to socket
            do {
                while true {
                    // read length
                    let length = try self.readNativeInt32()
                    guard let data = try self.readNativeString(withLength: length) else {
                        NSLog("Invalid value for string")
                        continue
                    }
                    
                    do {
                        try self.handler?.writeSocket(string: data)
                    } catch let error {
                        NSLog("Error while writing to socket: \(error)")
                        // close the socket
                        self.handler?.socket?.close()
                    }
                }
                
            } catch let error {
                guard case NativeError.eofError = error else {
                    NSLog("Error while stream reading: \(error)")
                    Darwin.exit(-1)
                }
            }
            
            self.end = true
            self.handler?.socket?.close()
            self.unixSocket?.close()
        }
    }
    
    func run() {
        let addr = BridgeConstants.buildSocketPath()
        NSLog("Socket at \(addr)")
        
        handleNative()
        
        // echo the stuff
        let queue = DispatchQueue.global(qos: .default)
        queue.async {
            do {
                self.unixSocket = try! Socket.create(family: .unix, type: .stream, proto: .unix)
                try self.unixSocket?.listen(on: addr)
                
                while !self.end {
                    let socket = try self.unixSocket?.acceptClientConnection()
                    NSLog("Got new socket connection")
                    self.handler = ConnectionHandler(withSocket: socket!)
                    self.handler?.handleConnection()
                    self.handler = nil
                }
            } catch let error {
                NSLog("Got error \(error)")
                Darwin.exit(-1)
            }
        }
        
        dispatchMain()
    }
}

let bridge = MusiControlBridge()
bridge.run()
