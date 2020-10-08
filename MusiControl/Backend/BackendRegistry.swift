//__FILENAME__

import Foundation

class BackendRegistry {
    var delegate: MusiBackendDelegate? = nil {
        didSet {
            if let backend = currentBackend {
                backend.delegate = delegate
            }
        }
    }
    
    private(set) var backends = [MusiBackend]()
    var currentBackend: MusiBackend? = nil {
        didSet {
            oldValue?.disconnect()
            
            currentBackend?.delegate = delegate
        }
    }
    
    init() {
        register(backend: BrowserBackend())
        register(backend: SpotifyBackend())
        // TODO store this
        currentBackend = self["Browser"]
    }
    
    subscript(index: String) -> MusiBackend? {
        get {
            backends.first(where: { $0.name == index })
        }
    }
    
    func register(backend: MusiBackend) {
        self.backends.append(backend)
    }
}
