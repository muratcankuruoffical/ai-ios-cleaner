//
//  BlurDetector.swift
//  AI Cleaner
//
//  Service for detecting blurry/low-quality images using Laplacian variance
//

import Foundation
import UIKit
import CoreImage
import Accelerate

final class BlurDetector {
    static let shared = BlurDetector()

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    private init() {}

    // MARK: - Configuration

    struct BlurThresholds {
        var veryBlurry: Float = 50.0
        var blurry: Float = 100.0
        var acceptable: Float = 200.0

        static let `default` = BlurThresholds()
        static let strict = BlurThresholds(veryBlurry: 100.0, blurry: 200.0, acceptable: 400.0)
    }

    enum BlurLevel {
        case veryBlurry
        case blurry
        case acceptable
        case sharp

        var description: String {
            switch self {
            case .veryBlurry: return "Very Blurry"
            case .blurry: return "Blurry"
            case .acceptable: return "Acceptable"
            case .sharp: return "Sharp"
            }
        }
    }

    // MARK: - Blur Detection

    func detectBlur(in image: UIImage, thresholds: BlurThresholds = .default) async throws -> (score: Float, level: BlurLevel) {
        guard let cgImage = image.cgImage else {
            throw BlurDetectorError.invalidImage
        }

        let score = try await calculateLaplacianVariance(cgImage: cgImage)
        let level = classifyBlur(score: score, thresholds: thresholds)

        return (score, level)
    }

    // MARK: - Laplacian Variance Calculation

    private func calculateLaplacianVariance(cgImage: CGImage) async throws -> Float {
        // Convert to grayscale for faster processing
        guard let grayImage = convertToGrayscale(cgImage: cgImage) else {
            throw BlurDetectorError.conversionFailed
        }

        // Apply Laplacian kernel
        let laplacian = applyLaplacianKernel(to: grayImage)

        // Calculate variance
        let variance = calculateVariance(of: laplacian)

        return variance
    }

    private func convertToGrayscale(cgImage: CGImage) -> CGImage? {
        let ciImage = CIImage(cgImage: cgImage)

        guard let filter = CIFilter(name: "CIPhotoEffectMono") else {
            return nil
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)

        guard let outputImage = filter.outputImage,
              let grayImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return grayImage
    }

    private func applyLaplacianKernel(to cgImage: CGImage) -> vImage_Buffer {
        let width = cgImage.width
        let height = cgImage.height

        // Create source buffer
        var sourceBuffer = vImage_Buffer()
        vImageBuffer_InitWithCGImage(
            &sourceBuffer,
            &vImage_CGImageFormat(cgImage: cgImage),
            nil,
            cgImage,
            vImage_Flags(kvImageNoFlags)
        )

        // Create destination buffer
        var destBuffer = vImage_Buffer()
        destBuffer.width = vUInt(width)
        destBuffer.height = vUInt(height)
        destBuffer.rowBytes = width
        destBuffer.data = UnsafeMutableRawPointer.allocate(
            byteCount: width * height,
            alignment: 16
        )

        // Laplacian kernel (approximation)
        var kernel: [Int16] = [
            0,  1,  0,
            1, -4,  1,
            0,  1,  0
        ]

        // Apply convolution
        vImageConvolve_Planar8(
            &sourceBuffer,
            &destBuffer,
            nil,
            0,
            0,
            &kernel,
            3,
            3,
            1,
            0,
            vImage_Flags(kvImageEdgeExtend)
        )

        // Clean up source buffer
        sourceBuffer.data.deallocate()

        return destBuffer
    }

    private func calculateVariance(of buffer: vImage_Buffer) -> Float {
        let count = Int(buffer.width * buffer.height)
        let data = buffer.data.assumingMemoryBound(to: UInt8.self)

        var sum: Int = 0
        var sumSquared: Int = 0

        for i in 0..<count {
            let value = Int(data[i])
            sum += value
            sumSquared += value * value
        }

        let mean = Float(sum) / Float(count)
        let meanSquared = Float(sumSquared) / Float(count)
        let variance = meanSquared - (mean * mean)

        // Clean up buffer
        buffer.data.deallocate()

        return variance
    }

    // MARK: - Alternative: CoreImage-based Detection

    func detectBlurUsingCoreImage(in image: UIImage) async throws -> Float {
        guard let cgImage = image.cgImage else {
            throw BlurDetectorError.invalidImage
        }

        let ciImage = CIImage(cgImage: cgImage)

        // Use CIEdges to detect edges
        guard let edgeFilter = CIFilter(name: "CISobelGradients") else {
            throw BlurDetectorError.filterNotAvailable
        }

        edgeFilter.setValue(ciImage, forKey: kCIInputImageKey)

        guard let outputImage = edgeFilter.outputImage else {
            throw BlurDetectorError.filterFailed
        }

        // Calculate average edge intensity
        let extent = outputImage.extent
        let downsampledExtent = CGRect(x: 0, y: 0, width: 100, height: 100)

        guard let outputCGImage = ciContext.createCGImage(outputImage, from: downsampledExtent) else {
            throw BlurDetectorError.filterFailed
        }

        let intensity = calculateAverageIntensity(cgImage: outputCGImage)

        return intensity * 1000 // Scale to comparable range
    }

    private func calculateAverageIntensity(cgImage: CGImage) -> Float {
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
            return 0
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var sum: Int = 0
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let r = Int(pixelData[i])
            let g = Int(pixelData[i + 1])
            let b = Int(pixelData[i + 2])
            sum += (r + g + b) / 3
        }

        return Float(sum) / Float(width * height)
    }

    // MARK: - Classification

    private func classifyBlur(score: Float, thresholds: BlurThresholds) -> BlurLevel {
        if score < thresholds.veryBlurry {
            return .veryBlurry
        } else if score < thresholds.blurry {
            return .blurry
        } else if score < thresholds.acceptable {
            return .acceptable
        } else {
            return .sharp
        }
    }

    // MARK: - Batch Processing

    func analyzeImages(
        _ images: [UIImage],
        progressHandler: ((Int, Int) -> Void)? = nil
    ) async throws -> [(score: Float, level: BlurLevel)] {
        var results: [(Float, BlurLevel)] = []

        for (index, image) in images.enumerated() {
            do {
                let result = try await detectBlur(in: image)
                results.append(result)
            } catch {
                print("Failed to analyze image \(index): \(error)")
                results.append((0, .veryBlurry))
            }

            progressHandler?(index + 1, images.count)

            if index % 10 == 0 {
                await Task.yield()
            }
        }

        return results
    }
}

// MARK: - Helper Extension

extension vImage_Buffer {
    init() {
        self.data = nil
        self.height = 0
        self.width = 0
        self.rowBytes = 0
    }
}

// MARK: - Helper Function

private func vImage_CGImageFormat(cgImage: CGImage) -> vImage_CGImageFormat {
    return vImage_CGImageFormat(
        bitsPerComponent: UInt32(cgImage.bitsPerComponent),
        bitsPerPixel: UInt32(cgImage.bitsPerPixel),
        colorSpace: Unmanaged.passRetained(cgImage.colorSpace ?? CGColorSpaceCreateDeviceGray()),
        bitmapInfo: cgImage.bitmapInfo,
        version: 0,
        decode: nil,
        renderingIntent: cgImage.renderingIntent
    )
}

// MARK: - Errors

enum BlurDetectorError: Error, LocalizedError {
    case invalidImage
    case conversionFailed
    case filterNotAvailable
    case filterFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .conversionFailed:
            return "Failed to convert image to grayscale"
        case .filterNotAvailable:
            return "Required image filter not available"
        case .filterFailed:
            return "Image filter processing failed"
        }
    }
}
