//__FILENAME__

import Cocoa
import Kingfisher
import CoreGraphics

class MainViewController: NSViewController, NSWindowDelegate {
    @IBOutlet weak var mainView: CustomView!
    @IBOutlet weak var nextView: CustomView!
    @IBOutlet weak var prevView: CustomView!
    @IBOutlet weak var shuffleView: CustomView!
    @IBOutlet weak var shuffleImageView: NSImageView!
    @IBOutlet weak var playView: CustomView!
    @IBOutlet weak var playImageView: NSImageView!
    @IBOutlet weak var coverView: NSImageView!
    @IBOutlet weak var coverViewContainer: NSView!
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var artistTextField: NSTextField!
    @IBOutlet weak var progressView: ProgressView!
    
    var outerViews: [CustomView] {
        [nextView, prevView, shuffleView, playView]
    }
    
    private var brightTint: NSColor = NSColor.controlAccentColor
    private var darkTint: NSColor = NSColor.controlAccentColor
    private var isTintColorful = false
    private var hadClick = false
    private var cursorStart: NSPoint? = nil
    
    private var lastApp: NSRunningApplication? = nil
    private var imageSeq: Int = 0
    
    var playerState: PlayerState = PlayerState() {
        didSet {
            refreshPlayerState()
        }
    }
    
    func selectTint() {
        let targetTint: NSColor
        if progressView.effectiveAppearance.name == .darkAqua {
            // dark mode
            targetTint = self.darkTint
        } else {
            targetTint = self.brightTint
        }
        
        if !isTintColorful {
            self.progressView.tint = NSColor.labelColor
        } else {
            self.progressView.tint = targetTint
        }
    }
    
    private func refreshPlayerState() {
        let defaultFg = NSColor(named: "customIconColor")!
        let activeFg = NSColor(named: "customActiveIconColor")!
        
        let state: [Bool] = [playerState.shuffle, playerState.playing]
        let imageView: [NSImageView] = [shuffleImageView, playImageView]
        let customView: [CustomView] = [shuffleView, playView]
        
        for (i, state) in state.enumerated() {
            let img = imageView[i]
            let custom = customView[i]
            if state {
                img.contentTintColor = activeFg
            } else {
                img.contentTintColor = defaultFg
            }
            
            custom.isActive = state
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == kVK_Space {
            togglePause()
        } else if event.keyCode == kVK_ANSI_A {
            prev()
        } else if event.keyCode == kVK_ANSI_D {
            next()
        }
    }
    
    func hotkeyPressed() {
        guard let win = view.window else {
            return
        }
        
        win.setIsVisible(true)
        
        let mouseLoc = NSEvent.mouseLocation
        cursorStart = mouseLoc
        let size = win.frame.size
        
        let target = NSPoint(x: mouseLoc.x - size.width / 2.0,
                             y: mouseLoc.y - size.height / 2.0)
        
        win.setFrameOrigin(target)
        
        lastApp = NSWorkspace.shared.frontmostApplication
        
        hadClick = false
        for view in outerViews {
            view.isPreselected = false
        }
        
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hotkeyReleased() {
        guard let win = view.window else {
            return
        }
        
        if !win.isVisible {
            // do nothing
            return
        }
        
        if !hadClick {
            let mouseLoc = NSEvent.mouseLocation
            let view = getSelected(mouseLoc)
            view?.onClicked?()
        }
        
        win.setIsVisible(false)
        lastApp?.activate(options: [.activateIgnoringOtherApps])
    }
    
    override func mouseMoved(with event: NSEvent) {
        if hadClick {
            return
        }
        
        guard let win = view.window else {
            return
        }
        
        let mouseLoc = win.convertPoint(toScreen: event.locationInWindow)
        let selectedView = getSelected(mouseLoc)
        for view in outerViews {
            view.isPreselected = selectedView == view
        }
    }
    
    override func scrollWheel(with event: NSEvent) {
        disableHover()
        
        let delta = Double(event.scrollingDeltaY)
        
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.changeVolume(by: delta)
        }
    }
    
    func getSelected(_ mouseLoc: NSPoint) -> CustomView? {
        guard let win = view.window else {
            return nil
        }
        
        let mid = cursorStart ?? NSPoint(x: win.frame.midX, y: win.frame.midY)
        let x = mouseLoc.x - mid.x
        let y = mouseLoc.y - mid.y
        let distSq = x * x + y * y
        if distSq > 75 * 75 {
            // detect action
            let pi = Double.pi
            let angle = Double(atan2(y, x))
            if angle > -pi/4 && angle <= pi/4 {
                // right, next track
                return nextView
            } else if angle > pi/4 && angle <= 3*pi/4 {
                // top, shuffle
                return shuffleView
            } else if angle > 3*pi/4 || angle <= -3*pi/4 {
                // left, prev
                return prevView
            } else {
                // bottom, play/pause
                return playView
            }
        }
        
        return nil
    }
    
    override func viewDidLayout() {
        selectTint()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do view setup here.
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.mainViewController = self
        }
        
        updateTrack(nil)
        updatePosition(0.0)
        
        coverViewContainer.wantsLayer = true
        coverViewContainer.canDrawSubviewsIntoLayer = true
        coverViewContainer.layer?.cornerRadius = 8
        coverViewContainer.layer?.masksToBounds = true
        
        let shadowViews: [NSView] = [mainView, nextView, prevView, shuffleView, playView]
        for view in shadowViews {
            view.wantsLayer = true
            view.layer?.masksToBounds = true
            view.layer?.cornerRadius = 8
            
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.shadowColor.withAlphaComponent(0.6)
            shadow.shadowOffset = NSMakeSize(0, -2)
            shadow.shadowBlurRadius = 10
            view.shadow = shadow
        }
        
        let roundViews: [NSView] = [nextView, prevView]
        for view in roundViews {
            view.layer?.cornerRadius = 32
        }
        
        mainView.onClicked = {
            if let delegate = NSApp.delegate as? AppDelegate {
                delegate.bringToForeground()
            }
        }
        
        nextView.onClicked = {
            self.disableHover()
            
            self.next()
        }
        
        prevView.onClicked = {
            self.disableHover()
            
            self.prev()
        }
        
        shuffleView.onClicked = {
            self.disableHover()
            
            self.toggleShuffle()
        }
        
        playView.onClicked = {
            self.disableHover()
            
            self.togglePause()
        }
    }
    
    func disableHover() {
        hadClick = true
        
        for view in outerViews {
            view.isPreselected = false
        }
    }
    
    func next() {
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.next()
        }
    }
    
    func prev() {
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.prev()
        }
    }
    
    func toggleShuffle() {
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.toggleShuffle()
            
            var state = self.playerState
            state.shuffle = !state.shuffle
            self.playerState = state
        }
    }
    
    func togglePause() {
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.togglePause()
            
            var state = self.playerState
            state.playing = !state.playing
            self.playerState = state
        }
    }
    
    override func viewWillAppear() {
        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.tryConnect()
        }
        
        view.window?.delegate = self
        view.window?.isOpaque = false
        view.window?.backgroundColor = NSColor.clear
        view.window?.level = .floating
        view.window?.acceptsMouseMovedEvents = true
    }
    
    func windowDidResignKey(_ notification: Notification) {
        // well we are gone
        view.window?.setIsVisible(false)
    }
    
    func calculateTint(fromImage img: NSImage) {
        let myImageSeq = imageSeq
        
        DispatchQueue.global(qos: .userInteractive).async {
            let quant = ImageQuantifier()
            quant.load(from: img)
            guard let cmap = quant.quantize(maxColors: 10) else {
                print("No cmap :(")
                return
            }
            
            var maxColor = CGFloat(0.0)
            var mostColorful: NSColor? = nil
            for color in cmap.palette {
                let nsColor = NSColor(srgbRed: CGFloat(color.r) / 255.0,
                                      green: CGFloat(color.g) / 255.0,
                                      blue: CGFloat(color.b) / 255.0,
                                      alpha: 1.0)
                
                let s = nsColor.saturationComponent
                let v = nsColor.brightnessComponent
                let brt = (1.0 - v)
                let colorVal = sqrt(s) * sqrt(v)
                if colorVal > maxColor && brt < 0.5 {
                    mostColorful = nsColor
                    maxColor = colorVal
                }
            }
            
            DispatchQueue.main.async {
                if self.imageSeq != myImageSeq {
                    // too late
                    return
                }
                
                guard let colorful = mostColorful else {
                    self.resetTint()
                    return
                }
                
                self.brightTint = NSColor(hue: colorful.hueComponent,
                                         saturation: max(CGFloat(0.9), colorful.saturationComponent),
                                         brightness: max(CGFloat(0.7), colorful.brightnessComponent),
                                         alpha: CGFloat(1.0))
                
                self.darkTint = NSColor(hue: mostColorful!.hueComponent,
                                        saturation: max(CGFloat(0.95), colorful.saturationComponent),
                                        brightness: max(CGFloat(0.95), colorful.brightnessComponent),
                                        alpha: CGFloat(1.0))
                
                self.isTintColorful = maxColor > 0.3
                self.selectTint()
            }
        }
    }
    
    func resetTint() {
        self.brightTint = NSColor.controlAccentColor
        self.darkTint = NSColor.controlAccentColor
        self.isTintColorful = false
        self.selectTint()
    }
    
    func updateTrack(_ track: Track?) {
        imageSeq += 1
        
        if let t = track {
            self.titleTextField.stringValue = t.title ?? "<unknown>"
            self.artistTextField.stringValue = t.artist ?? "<unknown>"
            if let cover = t.cover {
                let url = URL(string: cover)
                self.coverView.kf.indicatorType = .activity
                self.coverView.kf.setImage(with: url, options: [], progressBlock: nil, completionHandler:
                    {(result: Result<RetrieveImageResult, KingfisherError>) in
                        guard let img = (try? result.get())?.image else {
                            self.resetTint()
                            return
                        }
                        
                        self.calculateTint(fromImage: img)
                    })
            } else {
                self.coverView.image = NSImage(named: "unknownCoverImage")
            }
            self.progressView.duration = t.duration
        } else {
            self.titleTextField.stringValue = "No song playing"
            self.artistTextField.stringValue = ""
            self.coverView.image = NSImage(named: "unknownCoverImage")
            
            self.resetTint()
        }
    }
    
    func updatePosition(_ position: Double) {
        self.progressView.progress = position
    }
}
