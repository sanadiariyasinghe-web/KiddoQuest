import UIKit
import Vision

// MARK: - Image Classifier
// On-device image understanding for Find It!:
// • Vision's built-in classifier (ClassifyImageRequest) says what objects are in a photo,
// • the average colour of the centre of the photo says which colour the child is showing.
// Nothing leaves the device; no network or trained model files are needed.

enum ImageClassifier {
    /// Classifies a photo and returns (identifier, confidence) pairs, most confident first.
    static func classify(_ image: UIImage) async -> [(identifier: String, confidence: Float)] {
        guard let cgImage = image.cgImage else { return [] }
        do {
            let request = ClassifyImageRequest()
            let results = try await request.perform(on: cgImage, orientation: image.cgOrientation)
            return results
                .map { (identifier: $0.identifier, confidence: $0.confidence) }
                .sorted { $0.confidence > $1.confidence }
        } catch {
            return []
        }
    }

    /// The average colour (0...1 per channel) of the middle third of the photo,
    /// which is where a child naturally points the camera.
    static func centreColor(of image: UIImage) -> (red: Double, green: Double, blue: Double)? {
        guard let cgImage = image.cgImage else { return nil }
        let crop = CGRect(
            x: CGFloat(cgImage.width) / 3, y: CGFloat(cgImage.height) / 3,
            width: CGFloat(cgImage.width) / 3, height: CGFloat(cgImage.height) / 3
        )
        guard let centre = cgImage.cropping(to: crop) else { return nil }

        // Draw the centre into a tiny bitmap; the GPU-friendly downscale averages the pixels.
        let side = 8
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        guard let context = CGContext(
            data: &pixels, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.interpolationQuality = .medium
        context.draw(centre, in: CGRect(x: 0, y: 0, width: side, height: side))

        var totals = (red: 0.0, green: 0.0, blue: 0.0)
        for index in stride(from: 0, to: pixels.count, by: 4) {
            totals.red += Double(pixels[index])
            totals.green += Double(pixels[index + 1])
            totals.blue += Double(pixels[index + 2])
        }
        let count = Double(side * side) * 255
        return (totals.red / count, totals.green / count, totals.blue / count)
    }
}

extension UIImage {
    /// The photo's orientation in the form Vision expects.
    var cgOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
