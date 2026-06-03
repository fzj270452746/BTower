//
//  MJTTheme.swift
//  Mahjong Tower
//
//  Visual constants, colors and small UI helpers.
//

import UIKit

enum MJTTheme {

    // MARK: - Colors (jade / gold palette)
    static let jadeDark   = UIColor(red: 0.04, green: 0.20, blue: 0.16, alpha: 1.0)
    static let jade       = UIColor(red: 0.10, green: 0.42, blue: 0.34, alpha: 1.0)
    static let jadeLight  = UIColor(red: 0.22, green: 0.62, blue: 0.50, alpha: 1.0)
    static let gold       = UIColor(red: 0.92, green: 0.76, blue: 0.34, alpha: 1.0)
    static let goldDeep   = UIColor(red: 0.78, green: 0.58, blue: 0.18, alpha: 1.0)
    static let cream      = UIColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1.0)
    static let ink        = UIColor(red: 0.12, green: 0.14, blue: 0.16, alpha: 1.0)
    static let danger     = UIColor(red: 0.80, green: 0.26, blue: 0.24, alpha: 1.0)
    static let panel      = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.14)

    // MARK: - Fonts
    static func title(_ size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .heavy)
    }
    static func body(_ size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .semibold)
    }

    // MARK: - Layout
    static let buttonHeight: CGFloat = 60
    static let buttonCorner: CGFloat = 16

    // MARK: - Helpers
    static func gradientLayer(_ colors: [UIColor]) -> CAGradientLayer {
        let g = CAGradientLayer()
        g.colors = colors.map { $0.cgColor }
        g.startPoint = CGPoint(x: 0.5, y: 0.0)
        g.endPoint = CGPoint(x: 0.5, y: 1.0)
        return g
    }
}

extension UIColor {
    /// Suit accent color used for tile glyphs.
    static func mjtSuitColor(_ suit: MJTSuit) -> UIColor {
        switch suit {
        case .characters: return MJTTheme.danger
        case .dots:       return MJTTheme.jade
        }
    }
}

extension UIView {
    /// Quick press-down / release bounce used by all tappable controls.
    func mjtPressBounce() {
        UIView.animate(withDuration: 0.08, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: { _ in
            UIView.animate(withDuration: 0.10) { self.transform = .identity }
        })
    }
}

extension UIImage {
    /// Returns a copy cropped to its non-transparent content, removing the
    /// transparent padding baked into square button artwork. Falls back to
    /// the original image if it has no alpha or cannot be inspected.
    func mjtTrimmedTransparent(alphaThreshold: UInt8 = 10) -> UIImage {
        guard let cg = cgImage else { return self }
        let w = cg.width, h = cg.height
        guard w > 0, h > 0 else { return self }

        let bytesPerRow = w * 4
        var data = [UInt8](repeating: 0, count: bytesPerRow * h)
        let space = CGColorSpaceCreateDeviceRGB()
        let info = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(data: &data, width: w, height: h,
                                  bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                  space: space, bitmapInfo: info) else { return self }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        var minX = w, minY = h, maxX = -1, maxY = -1
        for y in 0..<h {
            let row = y * bytesPerRow
            for x in 0..<w {
                if data[row + x * 4 + 3] > alphaThreshold {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }
        guard maxX >= minX, maxY >= minY else { return self }

        let cropRect = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        guard let cropped = cg.cropping(to: cropRect) else { return self }
        return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
    }
}
