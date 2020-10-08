//__FILENAME__

import Cocoa

class ProgressView: NSView {

    var tint: NSColor = NSColor.controlAccentColor {
        didSet {
            setNeedsDisplay(self.bounds)
        }
    }
    
    var progress: Double = 30 {
        didSet {
            setNeedsDisplay(self.bounds)
        }
    }
    
    var duration: Int = 60 {
        didSet {
            setNeedsDisplay(self.bounds)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let width = Double(self.bounds.width)
        let actualWidth = width * (progress / Double(duration))

        tint.setFill()
        let figure = NSBezierPath(rect: NSRect(x: 0, y: 0, width: Int(actualWidth), height: 3))
        figure.fill()
    }
    
}
