//__FILENAME__

import Foundation

class BrowserBackend : MusiBackend, NativeHandlerDelegate {
    private var handler: NativeHandler? = nil
    private var sentConnected = false
    
    var delegate: MusiBackendDelegate?
    let name: String = "Browser"
    
    func connectionClosed() {
        delegate?.backendDidDisconnect()
        self.handler = nil
        self.sentConnected = false
    }
    
    func connectionError() {
        let alert = NSAlert()
        alert.messageText = "Connection failed"
        alert.informativeText = "Could not connect to browser addon. Is the browser running and the addon installed?"
        alert.alertStyle = .critical
        alert.runModal()
    }
    
    func messageReceived(_ message: JsonMessage) {
        if !sentConnected {
            sentConnected = true
            delegate?.backendDidConnect()
        }
        
        switch message.type {
        case "updateTrack":
            delegate?.trackDidChange(message.track)
            delegate?.positionDidChange(message.position!)
            
        case "updatePosition":
            delegate?.positionDidChange(message.position!)
            
        case "updatePlayerState":
            delegate?.playerStateDidChange(message.playerState!)
            
        default:
            break
        }
    }
    
    func connect() {
        if self.handler != nil {
            // do nothing
            return
        }
        
        let handler = NativeHandler()
        handler.delegate = self
        self.handler = handler
        handler.start()
    }
    
    func disconnect() {
        guard let handler = self.handler else {
            return
        }
        
        handler.disconnect()
        self.handler = nil
    }
    
    private func sendAction(_ action: String) {
        var msg = [String: Any]()
        msg["type"] = action
        let json = try! JSONSerialization.data(withJSONObject: msg, options: [])
        try? handler?.write(data: json)
    }
    
    func bringToForeground() {
        sendAction("open")
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: {
            let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.vivaldi.Vivaldi")
            if apps.count < 1 {
                return
            }
            let app = apps[0]
            app.activate(options: [])
        })
    }
    
    func togglePause() {
        sendAction("togglePause")
    }
    
    func prev() {
        sendAction("prev")
    }
    
    func next() {
        sendAction("next")
    }
    
    func toggleShuffle() {
        sendAction("toggleShuffle")
    }
    
    func changeVolume(by delta: Double) {
        var msg = [String: Any]()
        msg["type"] = "changeVolume"
        msg["volumeChange"] = delta
        let json = try! JSONSerialization.data(withJSONObject: msg, options: [])
        try? handler?.write(data: json)
    }
}
