//__FILENAME__

import Foundation

class NativeInstaller {
    func installBridge() {
        setHelperExecutable()
        installChrome()
        installFirefox()
    }
    
    private let name = "com.xxmicloxx.musicontrol.bridge"
    
    private var bridgePath: String {
        Bundle.main.path(forResource: "MusiControlBridge", ofType: nil)!
    }
    
    private var generalJsonObject: [String: Any] {
        var obj = [String: Any]()
        obj["name"] = name
        obj["description"] = "Bridge to MusiControl for usage with a browser addon"
        obj["type"] = "stdio"
        obj["path"] = bridgePath
        
        return obj
    }
    
    func setHelperExecutable() {
        var attrs = [FileAttributeKey : Any]()
        attrs[.posixPermissions] = 0o755
        do {
            try FileManager.default.setAttributes(attrs, ofItemAtPath: bridgePath)
        } catch let error {
            print("Could not make bridge executable: \(error)")
            NSApp.presentError(error)
        }
    }
    
    private func installVivaldi() {
        var jsonObj = generalJsonObject
        
        let allowedOrigins: [String] = ["chrome-extension://bammcdhdafecckeepbpfichifdbnmhfd/"]
        jsonObj["allowed_origins"] = allowedOrigins
        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonObj, options: [.prettyPrinted])
            
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            
            let chromeDir = appSupport
                .appendingPathComponent("Vivaldi", isDirectory: true)
                .appendingPathComponent("NativeMessagingHosts", isDirectory: true)
                .appendingPathComponent("\(name).json", isDirectory: false)
            
            try FileManager.default.createDirectory(at: chromeDir.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true, attributes: nil)
            
            try data.write(to: chromeDir, options: [.atomic])
        } catch let error {
            print("Could not write Chrome manifest")
            NSApp.presentError(error)
        }
    }
    
    private func installChrome() {
        var jsonObj = generalJsonObject
        
        let allowedOrigins: [String] = ["chrome-extension://bammcdhdafecckeepbpfichifdbnmhfd/"]
        jsonObj["allowed_origins"] = allowedOrigins
        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonObj, options: [.prettyPrinted])
            
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            
            let chromeDir = appSupport
                .appendingPathComponent("Google", isDirectory: true)
                .appendingPathComponent("Chrome", isDirectory: true)
                .appendingPathComponent("NativeMessagingHosts", isDirectory: true)
                .appendingPathComponent("\(name).json", isDirectory: false)
            
            try FileManager.default.createDirectory(at: chromeDir.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true, attributes: nil)
            
            try data.write(to: chromeDir, options: [.atomic])
        } catch let error {
            print("Could not write Chrome manifest")
            NSApp.presentError(error)
        }
    }
    
    private func installFirefox() {
        var jsonObj = generalJsonObject
        
        let allowedExtensions: [String] = ["musicontrol_deezer@xxmicloxx.com"]
        jsonObj["allowed_extensions"] = allowedExtensions
        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonObj, options: [.prettyPrinted])
            
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            
            let firefoxDir = appSupport
                .appendingPathComponent("Mozilla", isDirectory: true)
                .appendingPathComponent("NativeMessagingHosts", isDirectory: true)
                .appendingPathComponent("\(name).json", isDirectory: false)
            
            try FileManager.default.createDirectory(at: firefoxDir.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true, attributes: nil)
            
            try data.write(to: firefoxDir, options: [.atomic])
        } catch let error {
            print("Could not write Firefox manifest")
            NSApp.presentError(error)
        }
    }
}
