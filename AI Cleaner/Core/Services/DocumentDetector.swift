//
//  DocumentDetector.swift
//  AI Cleaner
//
//  Service for detecting documents, IDs, invoices using on-device OCR
//

import Foundation
import Vision
import UIKit
import Photos

final class DocumentDetector {
    static let shared = DocumentDetector()

    private init() {}

    // MARK: - Document Types

    enum DocumentType: String, CaseIterable {
        case idCard = "ID Card"
        case passport = "Passport"
        case driversLicense = "Driver's License"
        case invoice = "Invoice"
        case receipt = "Receipt"
        case creditCard = "Credit Card"
        case bankStatement = "Bank Statement"
        case document = "Document"
        case unknown = "Unknown"

        var icon: String {
            switch self {
            case .idCard: return "person.text.rectangle"
            case .passport: return "book.closed"
            case .driversLicense: return "car"
            case .invoice: return "doc.text"
            case .receipt: return "receipt"
            case .creditCard: return "creditcard"
            case .bankStatement: return "building.columns"
            case .document: return "doc"
            case .unknown: return "questionmark.circle"
            }
        }

        var isSensitive: Bool {
            switch self {
            case .idCard, .passport, .driversLicense, .creditCard, .bankStatement:
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Detection Result

    struct DocumentDetectionResult {
        let asset: PHAsset
        let documentType: DocumentType
        let confidence: Float
        let detectedText: [String]
        let keywords: [String]

        var isSensitive: Bool {
            documentType.isSensitive
        }
    }

    // MARK: - Configuration

    struct Configuration {
        /// Minimum confidence to consider a detection valid (0.0 - 1.0)
        var minimumConfidence: Float = 0.6

        /// Minimum number of keywords to match
        var minimumKeywordMatches: Int = 2

        /// Enable text recognition (OCR)
        var enableOCR: Bool = true

        static let `default` = Configuration()
    }

    // MARK: - Keywords Database

    private let documentKeywords: [DocumentType: [String]] = [
        .idCard: [
            "kimlik", "tc", "identity", "national", "id", "citizenship",
            "cumhuriyet", "türkiye", "republic", "card number", "date of birth",
            "doğum tarihi", "nüfus", "population"
        ],
        .passport: [
            "passport", "pasaport", "travel", "seyahat", "republic of",
            "türkiye cumhuriyeti", "passport no", "pasaport no", "surname",
            "soyadı", "nationality", "uyruk"
        ],
        .driversLicense: [
            "sürücü", "driver", "license", "lisans", "ehliyet", "driving",
            "vehicle", "araç", "class", "sınıf", "issue date", "veriliş"
        ],
        .invoice: [
            "invoice", "fatura", "bill", "amount", "tutar", "total", "toplam",
            "tax", "kdv", "vat", "invoice no", "fatura no", "date", "tarih"
        ],
        .receipt: [
            "receipt", "fiş", "makbuz", "paid", "ödendi", "cash", "nakit",
            "card", "kart", "total", "toplam", "thank you", "teşekkür"
        ],
        .creditCard: [
            "card", "kart", "credit", "kredi", "debit", "bankamatik",
            "visa", "mastercard", "expires", "son kullanma", "cvv", "cvc",
            "card number", "kart no"
        ],
        .bankStatement: [
            "bank", "banka", "statement", "hesap", "account", "balance",
            "bakiye", "transaction", "işlem", "deposit", "yatırım",
            "withdrawal", "çekim", "iban"
        ]
    ]

    // MARK: - Detect Documents in Batch

    func detectDocuments(
        in assets: [PHAsset],
        configuration: Configuration = .default,
        progressHandler: ((Int, Int) -> Void)? = nil
    ) async -> [DocumentDetectionResult] {
        var results: [DocumentDetectionResult] = []

        for (index, asset) in assets.enumerated() {
            guard asset.mediaType == .image else { continue }

            // Skip if it's already detected as screenshot (likely not a document photo)
            // Screenshots are usually UI, not scanned documents

            do {
                if let result = try await detectDocument(in: asset, configuration: configuration) {
                    results.append(result)
                }
            } catch {
                // Skip failed detections
                print("⚠️ Failed to detect document in asset \(asset.localIdentifier): \(error)")
            }

            progressHandler?(index + 1, assets.count)

            // Yield periodically
            if index % 10 == 0 {
                await Task.yield()
            }
        }

        return results.sorted { $0.confidence > $1.confidence }
    }

    // MARK: - Detect Document in Single Image

    func detectDocument(
        in asset: PHAsset,
        configuration: Configuration = .default
    ) async throws -> DocumentDetectionResult? {
        // Load image for analysis
        let image = try await PhotoLibraryService.shared.loadAnalysisImage(for: asset)

        guard let cgImage = image.cgImage else {
            throw DocumentDetectorError.invalidImage
        }

        // Perform OCR if enabled
        var detectedText: [String] = []

        if configuration.enableOCR {
            detectedText = try await performOCR(on: cgImage)
        }

        // If no text detected, not a document
        guard !detectedText.isEmpty else {
            return nil
        }

        // Analyze detected text to determine document type
        let (documentType, keywords, confidence) = analyzeText(detectedText, configuration: configuration)

        // If confidence is too low, skip
        guard confidence >= configuration.minimumConfidence else {
            return nil
        }

        return DocumentDetectionResult(
            asset: asset,
            documentType: documentType,
            confidence: confidence,
            detectedText: detectedText,
            keywords: keywords
        )
    }

    // MARK: - OCR (Text Recognition)

    private func performOCR(on image: CGImage) async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                // Extract text from observations
                var recognizedText: [String] = []

                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    recognizedText.append(topCandidate.string)
                }

                continuation.resume(returning: recognizedText)
            }

            // Configure recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            // Support multiple languages
            request.recognitionLanguages = ["en-US", "tr-TR"]

            // Perform the request
            let handler = VNImageRequestHandler(cgImage: image, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Text Analysis

    private func analyzeText(
        _ text: [String],
        configuration: Configuration
    ) -> (documentType: DocumentType, keywords: [String], confidence: Float) {
        // Combine all text into one string for analysis
        let fullText = text.joined(separator: " ").lowercased()

        var bestMatch: DocumentType = .unknown
        var bestConfidence: Float = 0.0
        var matchedKeywords: [String] = []

        // Try to match against each document type
        for (docType, keywords) in documentKeywords {
            var matches = 0
            var foundKeywords: [String] = []

            for keyword in keywords {
                if fullText.contains(keyword.lowercased()) {
                    matches += 1
                    foundKeywords.append(keyword)
                }
            }

            // Calculate confidence based on keyword matches
            let confidence = Float(matches) / Float(keywords.count)

            // Must have minimum number of keyword matches
            if matches >= configuration.minimumKeywordMatches && confidence > bestConfidence {
                bestMatch = docType
                bestConfidence = confidence
                matchedKeywords = foundKeywords
            }
        }

        // If no specific type matched but we have text, it's a generic document
        if bestMatch == .unknown && text.count > 5 {
            // Lots of text = likely a document
            bestMatch = .document
            bestConfidence = 0.5
        }

        return (bestMatch, matchedKeywords, bestConfidence)
    }

    // MARK: - Statistics

    func groupByType(_ results: [DocumentDetectionResult]) -> [DocumentType: [DocumentDetectionResult]] {
        Dictionary(grouping: results) { $0.documentType }
    }

    func countSensitiveDocuments(_ results: [DocumentDetectionResult]) -> Int {
        results.filter { $0.isSensitive }.count
    }
}

// MARK: - Errors

enum DocumentDetectorError: Error, LocalizedError {
    case invalidImage
    case ocrFailed
    case noTextDetected

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image for document detection"
        case .ocrFailed:
            return "OCR text recognition failed"
        case .noTextDetected:
            return "No text detected in image"
        }
    }
}
