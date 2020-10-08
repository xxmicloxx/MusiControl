//__FILENAME__

import Cocoa

@objc
class SettingsWindowController: NSWindowController, NSWindowDelegate {
    @IBOutlet weak var sourceMenu: NSMenu!
    @IBOutlet weak var sourceDropdown: NSPopUpButton!
    
    override func windowDidLoad() {
        guard let delegate = NSApp.delegate as? AppDelegate else {
            window?.close()
            return
        }
        
        var currentItem: NSMenuItem? = nil
        for backend in delegate.backendRegistry.backends {
            let item = NSMenuItem(title: backend.name, action: #selector(changeBackend), keyEquivalent: "")
            item.representedObject = backend
            sourceMenu.addItem(item)
            
            if backend === delegate.backendRegistry.currentBackend {
                currentItem = item
            }
        }
        
        sourceDropdown.select(currentItem)
    }
    
    func windowWillClose(_ notification: Notification) {
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.settingsClosed()
        }
    }
    
    @objc
    private func changeBackend(_ item: NSMenuItem) {
        guard let delegate = NSApp.delegate as? AppDelegate,
            let backend = item.representedObject as? MusiBackend else {
            return
        }
        
        // TODO change backend
        if let oldBackend = delegate.backendRegistry.currentBackend {
            oldBackend.disconnect()
        }
        
        delegate.backendRegistry.currentBackend = backend
    }
}
