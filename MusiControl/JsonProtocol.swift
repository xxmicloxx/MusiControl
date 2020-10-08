//__FILENAME__

import Foundation

struct JsonMessage : Codable {
    var type: String? = nil
    var track: Track? = nil
    var position: Double? = nil
    var playerState: PlayerState? = nil
}
