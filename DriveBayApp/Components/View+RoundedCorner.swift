import SwiftUI

// MARK: - Corner OptionSet
public struct Corner: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let topLeft     = Corner(rawValue: 1 << 0)
    public static let topRight    = Corner(rawValue: 1 << 1)
    public static let bottomLeft  = Corner(rawValue: 1 << 2)
    public static let bottomRight = Corner(rawValue: 1 << 3)

    public static let all: Corner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

// MARK: - RoundedCornerShape
struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: Corner = .all

    func path(in rect: CGRect) -> Path {
        #if canImport(UIKit)
        var maskedCorners: UIRectCorner = []
        if corners.contains(.topLeft) { maskedCorners.insert(.topLeft) }
        if corners.contains(.topRight) { maskedCorners.insert(.topRight) }
        if corners.contains(.bottomLeft) { maskedCorners.insert(.bottomLeft) }
        if corners.contains(.bottomRight) { maskedCorners.insert(.bottomRight) }

        let bezier = UIBezierPath(roundedRect: rect,
                                  byRoundingCorners: maskedCorners,
                                  cornerRadii: CGSize(width: radius, height: radius))
        return Path(bezier.cgPath)
        #elseif canImport(AppKit)
        var path = Path()
        // Compute corner centers
        let tl = CGPoint(x: rect.minX + radius, y: rect.minY + radius)
        let tr = CGPoint(x: rect.maxX - radius, y: rect.minY + radius)
        let bl = CGPoint(x: rect.minX + radius, y: rect.maxY - radius)
        let br = CGPoint(x: rect.maxX - radius, y: rect.maxY - radius)

        // Start at top-left
        path.move(to: CGPoint(x: rect.minX, y: corners.contains(.topLeft) ? rect.minY + radius : rect.minY))

        // Top edge
        path.addLine(to: CGPoint(x: corners.contains(.topRight) ? rect.maxX - radius : rect.maxX, y: rect.minY))
        // Top-right corner
        if corners.contains(.topRight) {
            path.addRelativeArc(center: tr, radius: radius, startAngle: .degrees(270), delta: .degrees(90))
        }

        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: corners.contains(.bottomRight) ? rect.maxY - radius : rect.maxY))
        // Bottom-right corner
        if corners.contains(.bottomRight) {
            path.addRelativeArc(center: br, radius: radius, startAngle: .degrees(0), delta: .degrees(90))
        }

        // Bottom edge
        path.addLine(to: CGPoint(x: corners.contains(.bottomLeft) ? rect.minX + radius : rect.minX, y: rect.maxY))
        // Bottom-left corner
        if corners.contains(.bottomLeft) {
            path.addRelativeArc(center: bl, radius: radius, startAngle: .degrees(90), delta: .degrees(90))
        }

        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: corners.contains(.topLeft) ? rect.minY + radius : rect.minY))
        // Top-left corner
        if corners.contains(.topLeft) {
            path.addRelativeArc(center: tl, radius: radius, startAngle: .degrees(180), delta: .degrees(90))
        }

        path.closeSubpath()
        return path
        #else
        return Path(roundedRect: rect, cornerRadius: radius)
        #endif
    }
}

// MARK: - View extension
public extension View {
    /// Rounds specific corners of the view
    /// - Parameters:
    ///   - radius: corner radius
    ///   - corners: which corners to round
    /// - Returns: a view with specified corners rounded
    func roundedCorner(_ radius: CGFloat, corners: Corner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}
