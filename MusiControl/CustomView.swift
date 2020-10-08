//__FILENAME__

import Cocoa

class CustomView: NSView {
    
    override var acceptsFirstResponder: Bool {
        true
    }
    
    private var isDown = false {
        didSet {
            layer?.setNeedsDisplay()
        }
    }
    
    var isActive = false {
        didSet {
            layer?.setNeedsDisplay()
        }
    }
    
    var tintColor: NSColor {
        isActive ? NSColor(named: "customActiveBackgroundColor")! : NSColor(named: "customBackgroundColor")!
    }
    
    var pressedColor: NSColor {
        isActive ? NSColor(named: "customActivePressedColor")! : NSColor(named: "customPressedColor")!
    }
    
    private var backgroundColor: NSColor {
        isDown != isPreselected ? pressedColor : tintColor
    }
    
    var onClicked: (() -> Void)? = nil
    
    var isPreselected: Bool = false {
        didSet {
            if oldValue != isPreselected {
                // changed
                layer?.setNeedsDisplay()
            }
        }
    }
    
    override func updateTrackingAreas() {
        self.trackingAreas.forEach({
            removeTrackingArea($0)
        })
    }
    
    override func updateLayer() {
        layer?.backgroundColor = backgroundColor.cgColor
        //layer?.borderColor = borderColor.cgColor
        //layer?.borderWidth = 1.2
    }
    
    override func mouseDown(with event: NSEvent) {
        isDown = true
    }
    
    override func mouseUp(with event: NSEvent) {
        isDown = false
        self.onClicked?()
    }
}
