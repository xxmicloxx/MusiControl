//__FILENAME__

import Foundation

class SpotifyBackend : MusiBackend {
    var delegate: MusiBackendDelegate?
    
    let name: String = "Spotify"
    
    func connect() {
    }
    
    func disconnect() {
    }
    
    func bringToForeground() {
    }
    
    func togglePause() {
    }
    
    func prev() {
    }
    
    func next() {
    }
    
    func toggleShuffle() {
    }
    
    func changeVolume(by delta: Double) {
    }
}
