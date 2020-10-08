//__FILENAME__

import Cocoa
import Carbon


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, MusiBackendDelegate {
    weak var mainViewController: MainViewController? = nil
    
    private(set) var backendRegistry: BackendRegistry! = nil
    
    private var statusBarItem: NSStatusItem! = nil
    private var connectionStatusItem: NSMenuItem! = nil
    
    private var settingsWindowController: SettingsWindowController? = nil {
        didSet {
            if settingsWindowController != nil {
                NSApp.setActivationPolicy(.regular)
            } else {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
    
    func tryConnect() {
        backendRegistry.currentBackend?.connect()
    }
    
    func backendDidConnect() {
        connectionStatusItem.title = "Connected to \(backendRegistry.currentBackend?.name ?? "<error>")"
    }
    
    func backendDidDisconnect() {
        connectionStatusItem.title = "Not connected"
        mainViewController?.updateTrack(nil)
        mainViewController?.updatePosition(0)
        mainViewController?.playerState = PlayerState()
    }
    
    private func setupStatusBar() {
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.image = NSImage(named: "StatusIcon")
        
        let menu = NSMenu(title: "MusiControl")
        connectionStatusItem = menu.addItem(withTitle: "Not connected", action: nil, keyEquivalent: "")
        menu.addItem(withTitle: "Preferences…", action: #selector(showSettings), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(exit), keyEquivalent: "")
        
        statusBarItem.menu = menu
    }
    
    @objc
    func showSettings() {
        if let win = self.settingsWindowController {
            win.showWindow(self)
            win.window?.makeKeyAndOrderFront(self)
            return
        }
        
        let windowController = SettingsWindowController(windowNibName: "SettingsWindow")
        windowController.showWindow(self)
        self.settingsWindowController = windowController
    }
    
    @objc
    func exit() {
        NSApp.terminate(self)
    }
    
    func settingsClosed() {
        print("Settings closed")
        self.settingsWindowController = nil
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let nativeInstaller = NativeInstaller()
        nativeInstaller.installBridge()
        
        backendRegistry = BackendRegistry()
        backendRegistry.delegate = self
        
        let sc = MASShortcut(keyCode: kVK_F1, modifierFlags: [])
        MASShortcutMonitor.shared()?.register(sc, withAction: {
            // toggle visibility
            self.mainViewController?.hotkeyPressed()
        }, releaseAction: {
            self.mainViewController?.hotkeyReleased()
        })
        
        setupStatusBar()
        
        NSApp.hide(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        backendRegistry.currentBackend?.disconnect()
        // Insert code here to tear down your application
    }
    
    func trackDidChange(_ track: Track?) {
        mainViewController?.updateTrack(track)
    }
    
    func positionDidChange(_ position: Double) {
        mainViewController?.updatePosition(position)
    }
    
    func playerStateDidChange(_ playerState: PlayerState) {
        mainViewController?.playerState = playerState
    }
    
    func bringToForeground() {
        backendRegistry.currentBackend?.bringToForeground()
    }
    
    func togglePause() {
        backendRegistry.currentBackend?.togglePause()
    }
    
    func prev() {
        backendRegistry.currentBackend?.prev()
    }
    
    func next() {
        backendRegistry.currentBackend?.next()
    }
    
    func toggleShuffle() {
        backendRegistry.currentBackend?.toggleShuffle()
    }
    
    func changeVolume(by delta: Double) {
        backendRegistry.currentBackend?.changeVolume(by: delta)
    }
}

