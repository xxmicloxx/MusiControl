//__FILENAME__

import Foundation

class BridgeConstants {
    @available(*, unavailable) private init() {}
    
    static let Identifier = "com.xxmicloxxx.musicontrol.bridge";
    
    static func buildSocketPath() -> String {
        let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
        try! FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true, attributes: nil)
        let sockFile = tmpDir.appendingPathComponent(BridgeConstants.Identifier + ".socket")
        return sockFile.path
    }
}
