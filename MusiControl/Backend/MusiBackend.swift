//__FILENAME__

import Foundation

protocol MusiBackendDelegate {
    func trackDidChange(_ track: Track?)
    func positionDidChange(_ position: Double)
    func playerStateDidChange(_ playerState: PlayerState)
    
    func backendDidConnect()
    func backendDidDisconnect()
}

protocol MusiBackend : class {
    var delegate: MusiBackendDelegate? { get set }
    var name: String { get }
    
    func connect()
    func disconnect()
    
    func bringToForeground()
    func togglePause()
    func prev()
    func next()
    func toggleShuffle()
    func changeVolume(by delta: Double)
}
