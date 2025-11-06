//
//  VisionService.swift
//  AI Cleaner
//
//  Service for extracting image features using Vision framework
//

import Foundation
import Vision
import UIKit
import CoreImage

final class VisionService {
    static let shared = VisionService()

    private init() {}

    // MARK: - Feature Print Extraction

    func extractFeaturePrint(from image: UIImage) async throws -> VNFeaturePrintObservation {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            var isResumed = false
            let lock = NSLock()

            let request = VNGenerateImageFeaturePrintRequest { request, error in
                lock.lock()
                defer { lock.unlock() }

                guard !isResumed else {
                    // Continuation already resumed, ignore duplicate callback
                    return
                }
                isResumed = true

                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observation = request.results?.first as? VNFeaturePrintObservation else {
                    continuation.resume(throwing: VisionError.featureExtractionFailed)
                    return
                }

                continuation.resume(returning: observation)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                lock.lock()
                defer { lock.unlock() }

                guard !isResumed else {
                    // Continuation already resumed in completion handler
                    return
                }
                isResumed = true
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Feature Print Comparison

    func computeDistance(
        between observation1: VNFeaturePrintObservation,
        and observation2: VNFeaturePrintObservation
    ) throws -> Float {
        var distance: Float = 0

        try observation1.computeDistance(&distance, to: observation2)

        return distance
    }

    func areSimilar(
        _ observation1: VNFeaturePrintObservation,
        _ observation2: VNFeaturePrintObservation,
        threshold: Float = 0.25
    ) throws -> Bool {
        let distance = try computeDistance(between: observation1, and: observation2)
        return distance < threshold
    }

    // MARK: - Feature Print Serialization

    func serializeFeaturePrint(_ observation: VNFeaturePrintObservation) throws -> Data {
        // Extract the feature vector as Data
        let data = observation.data
        return data
    }

    func deserializeFeaturePrint(from data: Data) throws -> VNFeaturePrintObservation {
        // This is a workaround since VNFeaturePrintObservation can't be directly deserialized
        // We store the raw data and create observations on-the-fly during comparison
        // For now, we'll return nil and handle comparison differently
        throw VisionError.deserializationNotSupported
    }

    // MARK: - Batch Processing

    func extractFeaturePrints(
        from images: [UIImage],
        progressHandler: ((Int, Int) -> Void)? = nil
    ) async throws -> [VNFeaturePrintObservation?] {
        var results: [VNFeaturePrintObservation?] = []

        for (index, image) in images.enumerated() {
            do {
                let featurePrint = try await extractFeaturePrint(from: image)
                results.append(featurePrint)
            } catch {
                // Append nil for failed extraction
                results.append(nil)
            }

            progressHandler?(index + 1, images.count)

            // Yield periodically
            if index % 10 == 0 {
                await Task.yield()
            }
        }

        return results
    }
}

// MARK: - Feature Vector Storage Helper

struct FeatureVector {
    let data: Data
    let elementCount: Int

    init(from observation: VNFeaturePrintObservation) {
        self.data = observation.data
        self.elementCount = observation.elementCount
    }

    init(data: Data, elementCount: Int) {
        self.data = data
        self.elementCount = elementCount
    }

    func toFloatArray() -> [Float] {
        // Use stored elementCount, not derived from data size
        // This is critical because elementCount varies by iOS version
        var array = [Float](repeating: 0, count: elementCount)
        let bytesToCopy = min(data.count, elementCount * MemoryLayout<Float>.size)
        _ = array.withUnsafeMutableBytes { buffer in
            data.prefix(bytesToCopy).copyBytes(to: buffer)
        }
        return array
    }

    static func fromFloatArray(_ array: [Float]) -> Data {
        var array = array
        return array.withUnsafeBytes { Data($0) }
    }

    // Compute distance between two feature vectors
    static func distance(_ vector1: FeatureVector, _ vector2: FeatureVector) -> Float {
        let array1 = vector1.toFloatArray()
        let array2 = vector2.toFloatArray()

        guard array1.count == array2.count else {
            return Float.infinity
        }

        // Compute L2 (Euclidean) distance
        var sumSquaredDiff: Float = 0
        for i in 0..<array1.count {
            let diff = array1[i] - array2[i]
            sumSquaredDiff += diff * diff
        }

        return sqrt(sumSquaredDiff)
    }

    // Compute cosine distance
    static func cosineDistance(_ vector1: FeatureVector, _ vector2: FeatureVector) -> Float {
        let array1 = vector1.toFloatArray()
        let array2 = vector2.toFloatArray()

        guard array1.count == array2.count else {
            return Float.infinity
        }

        var dotProduct: Float = 0
        var norm1: Float = 0
        var norm2: Float = 0

        for i in 0..<array1.count {
            dotProduct += array1[i] * array2[i]
            norm1 += array1[i] * array1[i]
            norm2 += array2[i] * array2[i]
        }

        guard norm1 > 0 && norm2 > 0 else {
            return Float.infinity
        }

        let similarity = dotProduct / (sqrt(norm1) * sqrt(norm2))
        return 1.0 - similarity // Convert similarity to distance
    }
}

// MARK: - Errors

enum VisionError: Error, LocalizedError {
    case invalidImage
    case featureExtractionFailed
    case deserializationNotSupported

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .featureExtractionFailed:
            return "Failed to extract image features"
        case .deserializationNotSupported:
            return "Feature print deserialization not supported"
        }
    }
}
