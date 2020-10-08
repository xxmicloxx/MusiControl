//__FILENAME__

import Foundation
import Cocoa

struct Color {
    var r: Int = 0
    var g: Int = 0
    var b: Int = 0
}

class ImageQuantifier : NSObject {
    class VBox : Equatable {
        var val1: [Int] = [Int](repeating: 0, count: 3)
        var val2: [Int] = [Int](repeating: 0, count: 3)
        
        var r1: Int {
            get { val1[0] }
            set { val1[0] = newValue }
        }
        var r2: Int {
            get { val2[0] }
            set { val2[0] = newValue }
        }
        var g1: Int {
            get { val1[1] }
            set { val1[1] = newValue }
        }
        var g2: Int {
            get { val2[1] }
            set { val2[1] = newValue }
        }
        var b1: Int {
            get { val1[2] }
            set { val1[2] = newValue }
        }
        var b2: Int {
            get { val2[2] }
            set { val2[2] = newValue }
        }
        
        var histo: [Int]
        private unowned let parent: ImageQuantifier
        
        private var _volume: Int? = nil
        var volume: Int {
            if let vol = _volume {
                return vol
            }
            
            return forceVolume()
        }
        
        private var _count: Int? = nil
        var count: Int {
            if let cnt = _count {
                return cnt
            }
            
            return forceCount()
        }
        
        private var _avg: Color? = nil
        var avg: Color {
            if let avg = _avg {
                return avg
            }
            
            return forceAvg()
        }
        
        init(r1: Int, r2: Int, g1: Int, g2: Int, b1: Int, b2: Int, histo: [Int], parent: ImageQuantifier) {
            self.histo = histo
            self.parent = parent
            
            self.r1 = r1
            self.r2 = r2
            self.g1 = g1
            self.g2 = g2
            self.b1 = b1
            self.b2 = b2
        }
        
        func forceVolume() -> Int {
            let vol = (r2 - r1 + 1) * (g2 - g1 + 1) * (b2 - b1 + 1)
            self._volume = vol
            return vol
        }
        
        func forceCount() -> Int {
            var npix = 0
            var idx = 0
            for r in r1...r2 {
                for g in g1...g2 {
                    for b in b1...b2 {
                        idx = parent.getColorIndex(r: r, g: g, b: b)
                        npix += histo[idx]
                    }
                }
            }
            self._count = npix
            return npix
        }
        
        func forceAvg() -> Color {
            var ntot = 0.0
            let mult = 1 << (8 - parent.sigbits)
            let dMult = Double(mult)
            
            var rsum = 0.0
            var gsum = 0.0
            var bsum = 0.0
            
            var hval = 0.0
            var idx = 0
            for i in r1...r2 {
                for j in g1...g2 {
                    for k in b1...b2 {
                        idx = parent.getColorIndex(r: i, g: j, b: k)
                        hval = Double(histo[idx])
                        ntot += hval
                        rsum += (hval * (Double(i) + 0.5) * dMult)
                        gsum += (hval * (Double(j) + 0.5) * dMult)
                        bsum += (hval * (Double(k) + 0.5) * dMult)
                    }
                }
            }
            
            let avg: Color
            if ntot > 0.0 {
                avg = Color(r: Int(rsum / ntot), g: Int(gsum / ntot), b: Int(bsum / ntot))
            } else {
                avg = Color(
                    r: Int(dMult * Double(r1 + r2 + 1) / 2.0),
                    g: Int(dMult * Double(g1 + g2 + 1) / 2.0),
                    b: Int(dMult * Double(b1 + b2 + 1) / 2.0)
                )
            }
            
            self._avg = avg
            return avg
        }
        
        func contains(_ pixel: Color) -> Bool {
            let rval = pixel.r >> parent.rshift
            let gval = pixel.g >> parent.rshift
            let bval = pixel.b >> parent.rshift
            
            return (rval >= r1 && rval <= r2 &&
                gval >= g1 && gval <= g2 &&
                bval >= b1 && bval <= b2)
        }
        
        func copy() -> VBox {
            return VBox(r1: r1, r2: r2, g1: g1, g2: g2, b1: b1, b2: b2, histo: histo, parent: parent)
        }
        
        static func == (lhs: VBox, rhs: VBox) -> Bool {
            return lhs.val1 == rhs.val1 && lhs.val2 == rhs.val2
        }
    }
    
    class CMap {
        private var vboxes = PriorityQueue<VBox>(order: { (a: VBox, b: VBox) in
            let aval = a.count * a.volume
            let bval = b.count * b.volume
            
            return aval < bval
        })
        
        func push(box: VBox) {
            vboxes.push(box)
        }
        
        var palette: [Color] {
            vboxes.map({ $0.avg })
        }
        
        var count: Int {
            vboxes.count
        }
        
        func nearest(_ color: Color) -> Color? {
            var tColor: Color? = nil
            var d1: Double? = nil
            var d2: Double = 0
            
            for box in vboxes {
                d2 = sqrt(
                    pow(Double(color.r - box.avg.r), 2) +
                    pow(Double(color.g - box.avg.g), 2) +
                    pow(Double(color.b - box.avg.b), 2)
                )
                
                if d1 == nil || d2 < d1! {
                    d1 = d2
                    tColor = box.avg
                }
            }
            
            return tColor
        }
        
        func map(_ color: Color) -> Color? {
            for box in vboxes {
                if box.contains(color) {
                    return box.avg
                }
            }
            
            return nearest(color)
        }
    }
    
    var pixels = [Color]()
    
    var sigbits = 5
    var maxIterations = 1000
    var fractByPopulations = 0.75
    
    var rshift: Int {
        8 - sigbits
    }
    
    func getColorIndex(r: Int, g: Int, b: Int) -> Int {
        return (r << (2 * sigbits)) + (g << sigbits) + b
    }
    
    func load(from img: NSImage, maxResolution: Int? = 75) {
        let size = img.size
        var width = size.width
        var height = size.height
        
        if let res = maxResolution {
            width = min(CGFloat(res), width)
            height = min(CGFloat(res), height)
        }
        
        let rect = NSMakeRect(0, 0, width, height)
        
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let ctx = CGContext(
            data: nil,
            width: Int(width), height: Int(height),
            bitsPerComponent: 8, bytesPerRow: 4*Int(size.width),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        
        let gctx = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.current = gctx
        img.draw(in: rect)
        
        let w = ctx.width
        let h = ctx.height
        let data = ctx.data!
        var offset = 0
        
        print("Loading pixels from \(w)x\(h) image")
        
        pixels.removeAll()
        pixels.reserveCapacity(w * h)
        for _ in 0..<h {
            for _ in 0..<w {
                let target: Int32 = data.load(fromByteOffset: offset, as: Int32.self)
                offset += MemoryLayout<Int32>.size
                
                let red = target & 0x000000ff
                let green = (target & 0x0000ff00) >> 8
                let blue = (target & 0x00ff0000) >> 16
                
                let pixel = Color(r: Int(red), g: Int(green), b: Int(blue))
                pixels.append(pixel)
            }
        }
        
        NSGraphicsContext.current = nil
    }
    
    func generateHisto() -> [Int] {
        let histosize = 1 << (3 * sigbits)
        var histo = [Int](repeating: 0, count: histosize)
        var index: Int = 0
        
        var rval = 0
        var gval = 0
        var bval = 0
        
        for pixel in pixels {
            rval = pixel.r >> rshift
            gval = pixel.g >> rshift
            bval = pixel.b >> rshift
            index = getColorIndex(r: rval, g: gval, b: bval)
            histo[index] += 1
        }
        
        return histo
    }
    
    func generateVBox(withHisto histo: [Int]) -> VBox {
        var rmin = Int.max
        var rmax = 0
        var gmin = Int.max
        var gmax = 0
        var bmin = Int.max
        var bmax = 0
        
        var rval = 0
        var gval = 0
        var bval = 0
        
        for pixel in pixels {
            rval = pixel.r >> rshift
            gval = pixel.g >> rshift
            bval = pixel.b >> rshift
            
            rmin = min(rmin, rval)
            rmax = max(rmax, rval)
            gmin = min(gmin, gval)
            gmax = max(gmax, gval)
            bmin = min(bmin, bval)
            bmax = max(bmax, bval)
        }
        
        return VBox(r1: rmin, r2: rmax, g1: gmin, g2: gmax, b1: bmin, b2: bmax, histo: histo, parent: self)
    }
    
    func medianCutApply(histo: [Int], vbox: VBox) -> [VBox] {
        if vbox.count == 0 {
            return []
        }
        
        let rw = vbox.r2 - vbox.r1 + 1
        let gw = vbox.g2 - vbox.g1 + 1
        let bw = vbox.b2 - vbox.b1 + 1
        let maxw = max(rw, gw, bw)
        if vbox.count == 1 {
            return [vbox.copy()]
        }
        
        var total = 0,
            partialsum = [Int](repeating: 0, count: 1 << sigbits),
            lookaheadsum = [Int](repeating: 0, count: 1 << sigbits),
            sum = 0, index = 0
        
        if maxw == rw {
            for i in vbox.r1...vbox.r2 {
                sum = 0
                for j in vbox.g1...vbox.g2 {
                    for k in vbox.b1...vbox.b2 {
                        index = getColorIndex(r: i, g: j, b: k)
                        sum += histo[index]
                    }
                }
                total += sum
                partialsum[i] = total
            }
        } else if maxw == gw {
            for i in vbox.g1...vbox.g2 {
                sum = 0
                for j in vbox.r1...vbox.r2 {
                    for k in vbox.b1...vbox.b2 {
                        index = getColorIndex(r: j, g: i, b: k)
                        sum += histo[index]
                    }
                }
                total += sum
                partialsum[i] = total
            }
        } else {
            for i in vbox.b1...vbox.b2 {
                sum = 0
                for j in vbox.r1...vbox.r2 {
                    for k in vbox.g1...vbox.g2 {
                        index = getColorIndex(r: j, g: k, b: i)
                        sum += histo[index]
                    }
                }
                total += sum
                partialsum[i] = total
            }
        }
        
        for (i, d) in partialsum.enumerated() {
            lookaheadsum[i] = total - d
        }
        
        func doCut(color: Int) -> [VBox] {
            var left = 0, right = 0, d2 = 0, count2 = 0
            let mmin = vbox.val1[color]
            let mmax = vbox.val2[color]
            
            for i in mmin...mmax {
                if Double(partialsum[i]) > Double(total)/2.0 {
                    // found target
                    let vbox1 = vbox.copy()
                    let vbox2 = vbox.copy()
                    
                    left = i - mmin
                    right = mmax - i
                    if left <= right {
                        d2 = min(mmax - 1, Int(Double(i) + Double(right) / 2.0))
                    } else {
                        d2 = max(mmin, Int(Double(i) - 1.0 - Double(left) / 2.0))
                    }
                    if d2 < 0 {
                        d2 = 0
                    }
                    // avoud 0-count boxes
                    while partialsum[d2] == 0 {
                        d2 += 1
                    }
                    count2 = lookaheadsum[d2]
                    while count2 == 0 && d2 > 0 && partialsum[d2 - 1] != 0 {
                        d2 -= 1
                        count2 = lookaheadsum[d2]
                    }
                    
                    d2 = max(min(30, d2), 0)
                    vbox1.val1[color] = min(d2, vbox1.val1[color])
                    vbox1.val2[color] = d2
                    vbox2.val1[color] = d2 + 1
                    vbox2.val2[color] = max(d2 + 1, vbox2.val2[color])
                    
                    return [vbox1, vbox2]
                }
            }
            
            return [vbox.copy()]
        }
        
        return maxw == rw ? doCut(color: 0) : maxw == gw ? doCut(color: 1) : doCut(color: 2)
    }
    
    func quantize(maxColors: Int) -> CMap? {
        if pixels.isEmpty || maxColors < 2 || maxColors > 256 {
            return nil
        }
        
        let histo = generateHisto()
        
        let vbox = generateVBox(withHisto: histo)
        var pq = PriorityQueue<VBox>(order: { (a: VBox, b: VBox) in
            return a.count < b.count
        })
        pq.push(vbox)
        
        func iter(_ lh: inout PriorityQueue<VBox>, withTarget target: Double) {
            var ncolors = Double(lh.count)
            var niters = 0
            
            while niters < maxIterations {
                if ncolors >= target {
                    return
                }
                if niters > maxIterations {
                    return
                }
                
                niters += 1
                guard let vbox = lh.pop() else {
                    return
                }
                
                if vbox.count == 0 {
                    lh.push(vbox)
                    niters += 1
                    continue
                }
                
                let vboxes = medianCutApply(histo: histo, vbox: vbox)
                
                if vboxes.isEmpty {
                    return
                }
                
                lh.push(vboxes[0])
                if vboxes.count >= 2 {
                    lh.push(vboxes[1])
                    ncolors += 1.0
                }
            }
        }
        
        iter(&pq, withTarget: fractByPopulations * Double(maxColors))
        
        var pq2 = PriorityQueue<VBox>(order: { (a: VBox, b: VBox) in
            let aval = a.count * a.volume
            let bval = b.count * b.volume
            return aval < bval
        })
        
        while !pq.isEmpty {
            guard let box = pq.pop() else {
                break
            }
            
            pq2.push(box)
        }
        
        iter(&pq2, withTarget: Double(maxColors))
        
        let cmap = CMap()
        while !pq2.isEmpty {
            guard let box = pq2.pop() else {
                break
            }
            
            cmap.push(box: box)
        }
        
        return cmap
    }
}
