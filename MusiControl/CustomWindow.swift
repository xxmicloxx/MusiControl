//__FILENAME__

import Cocoa

class CustomWindow: NSWindow {
    override var canBecomeKey: Bool {
        true
    }
    
    override var canBecomeMain: Bool {
        true
    }
    
    override var acceptsFirstResponder: Bool {
        true
    }
}
