//__FILENAME__

import Foundation

struct Track : Codable {
    var title: String? = nil
    var artist: String? = nil
    var album: String? = nil
    var cover: String? = nil
    var duration: Int = 0
}

struct PlayerState : Codable {
    var shuffle: Bool = false
    var playing: Bool = false
}
