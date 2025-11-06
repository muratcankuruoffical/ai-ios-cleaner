//
//  DarknessDetector.swift
//  AI Cleaner
//
//  Service for detecting dark/low-contrast images
//

import Foundation
import UIKit
import CoreImage

final class DarknessDetector {
    static let shared = DarknessDetector()

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    private init() {}

    // MARK: - Configuration

    struct BrightnessThresholds {
        var veryDark: Float = 0.15
        var dark: Float = 0.30
        var normal: Float = 0.70

        static let `default` = BrightnessThresholds()
    }

    enum BrightnessLevel {
        case veryDark
        case dark
        case normal
        case bright
        case veryBright

        var description: String {
            switch self {
            case .veryDark: return "Very Dark"
            case .dark: return "Dark"
            case .normal: return "Normal"
            case .bright: return "Bright"
            case .veryBright: return "Very Bright"
            }
        }

        var isProblematic: Bool {
            self == .veryDark || self == .veryBright
        }
    }

    struct AnalysisResult {
        let brightnessScore: Float // 0.0 - 1.0
        let contrastScore: Float // 0.0 - 1.0
        let level: BrightnessLevel
        let histogram: [Int] // 256 bins
    }

    // MARK: - Brightness Detection

    func analyzeBrightness(
        in image: UIImage,
        thresholds: BrightnessThresholds = .default
    ) async throws -> AnalysisResult {
        guard let cgImage = image.cgImage else {
            throw DarknessDetectorError.invalidImage
        }

        let histogram = calculateHistogram(cgImage: cgImage)
        let brightnessScore = calculateAverageBrightness(histogram: histogram)
        let contrastScore = calculateContrast(histogram: histogram)
        let level = classifyBrightness(score: brightnessScore, thresholds: thresholds)

        return AnalysisResult(
            brightnessScore: brightnessScore,
            contrastScore: contrastScore,
            level: level,
            histogram: histogram
        )
    }

    // MARK: - Histogram Calculation

    private func calculateHistogram(cgImage: CGImage) -> [Int] {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return Array(repeating: 0, count: 256)
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var histogram = [Int](repeating: 0, count: 256)

        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let r = Int(pixelData[i])
            let g = Int(pixelData[i + 1])
            let b = Int(pixelData[i + 2])

            // Calculate luminance using standard weights
            let luminance = Int(0.299 * Float(r) + 0.587 * Float(g) + 0.114 * Float(b))
            histogram[min(luminance, 255)] += 1
        }

        return histogram
    }

    // MARK: - Metrics Calculation

    private func calculateAverageBrightness(histogram: [Int]) -> Float {
        var totalPixels = 0
        var weightedSum = 0

        for (value, count) in histogram.enumerated() {
            totalPixels += count
            weightedSum += value * count
        }

        guard totalPixels > 0 else { return 0 }

        return Float(weightedSum) / Float(totalPixels) / 255.0
    }

    private func calculateContrast(histogram: [Int]) -> Float {
        var min: Int = 255
        var max: Int = 0

        let totalPixels = histogram.reduce(0, +)
        let threshold = Int(Float(totalPixels) * 0.01) // Ignore bottom/top 1%

        var accumulated = 0
        for (value, count) in histogram.enumerated() {
            accumulated += count
            if accumulated >= threshold && min == 255 {
                min = value
            }
            if accumulated >= (totalPixels - threshold) {
                max = value
                break
            }
        }

        let range = max - min
        return Float(range) / 255.0
    }

    private func calculateStandardDeviation(histogram: [Int], mean: Float) -> Float {
        var totalPixels = 0
        var variance: Float = 0

        for (value, count) in histogram.enumerated() {
            totalPixels += count
            let diff = Float(value) - (mean * 255.0)
            variance += diff * diff * Float(count)
        }

        guard totalPixels > 0 else { return 0 }

        variance /= Float(totalPixels)
        return sqrt(variance) / 255.0
    }

    // MARK: - Classification

    private func classifyBrightness(score: Float, thresholds: BrightnessThresholds) -> BrightnessLevel {
        if score < thresholds.veryDark {
            return .veryDark
        } else if score < thresholds.dark {
            return .dark
        } else if score < thresholds.normal {
            return .normal
        } else if score < 0.85 {
            return .bright
        } else {
            return .veryBright
        }
    }

    // MARK: - CoreImage-based Detection (Alternative)

    func analyzeBrightnessUsingCoreImage(in image: UIImage) async throws -> (brightness: Float, contrast: Float) {
        guard let cgImage = image.cgImage else {
            throw DarknessDetectorError.invalidImage
        }

        let ciImage = CIImage(cgImage: cgImage)

        // Calculate average color
        let extentVector = CIVector(
            x: ciImage.extent.origin.x,
            y: ciImage.extent.origin.y,
            z: ciImage.extent.size.width,
            w: ciImage.extent.size.height
        )

        guard let areaAverage = CIFilter(name: "CIAreaAverage") else {
            throw DarknessDetectorError.filterNotAvailable
        }

        areaAverage.setValue(ciImage, forKey: kCIInputImageKey)
        areaAverage.setValue(extentVector, forKey: kCIInputExtentKey)

        guard let outputImage = areaAverage.outputImage else {
            throw DarknessDetectorError.filterFailed
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        ciContext.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        let r = Float(bitmap[0]) / 255.0
        let g = Float(bitmap[1]) / 255.0
        let b = Float(bitmap[2]) / 255.0

        let brightness = (r + g + b) / 3.0

        // Simple contrast estimation
        let maxChannel = max(r, g, b)
        let minChannel = min(r, g, b)
        let contrast = maxChannel - minChannel

        return (brightness, contrast)
    }

    // MARK: - Batch Processing

    func analyzeImages(
        _ images: [UIImage],
        progressHandler: ((Int, Int) -> Void)? = nil
    ) async throws -> [AnalysisResult] {
        var results: [AnalysisResult] = []

        for (index, image) in images.enumerated() {
            do {
                let result = try await analyzeBrightness(in: image)
                results.append(result)
            } catch {
                print("Failed to analyze image \(index): \(error)")
                // Return default dark result on failure
                results.append(AnalysisResult(
                    brightnessScore: 0,
                    contrastScore: 0,
                    level: .veryDark,
                    histogram: Array(repeating: 0, count: 256)
                ))
            }

            progressHandler?(index + 1, images.count)

            if index % 10 == 0 {
                await Task.yield()
            }
        }

        return results
    }

    // MARK: - Utility Methods

    func findDarkImages(
        results: [AnalysisResult],
        threshold: Float = 0.30
    ) -> [Int] {
        results.enumerated().compactMap { index, result in
            result.brightnessScore < threshold ? index : nil
        }
    }

    func findLowContrastImages(
        results: [AnalysisResult],
        threshold: Float = 0.20
    ) -> [Int] {
        results.enumerated().compactMap { index, result in
            result.contrastScore < threshold ? index : nil
        }
    }
}

// MARK: - Errors

enum DarknessDetectorError: Error, LocalizedError {
    case invalidImage
    case filterNotAvailable
    case filterFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .filterNotAvailable:
            return "Required image filter not available"
        case .filterFailed:
            return "Image filter processing failed"
        }
    }
}
