//
//  SystemInsights.swift
//  AI Cleaner
//
//  Service for gathering system insights (battery, storage, etc.)
//

import Foundation
import UIKit

final class SystemInsights {
    static let shared = SystemInsights()

    private init() {
        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    // MARK: - Battery Info

    struct BatteryInfo {
        let level: Float // 0.0 - 1.0
        let state: UIDevice.BatteryState
        let isCharging: Bool
        let isLowPowerModeEnabled: Bool

        var percentage: Int {
            Int(level * 100)
        }

        var statusIcon: String {
            if isCharging {
                return "battery.100.bolt"
            }

            switch percentage {
            case 0...20: return "battery.0"
            case 21...50: return "battery.25"
            case 51...75: return "battery.50"
            case 76...99: return "battery.75"
            default: return "battery.100"
            }
        }

        var statusColor: String {
            if isCharging {
                return "green"
            }

            switch percentage {
            case 0...20: return "red"
            case 21...50: return "orange"
            default: return "green"
            }
        }

        var statusText: String {
            if state == .unknown {
                return "Unknown"
            }

            if isCharging {
                return "Charging (\(percentage)%)"
            }

            if isLowPowerModeEnabled {
                return "Low Power Mode (\(percentage)%)"
            }

            return "\(percentage)%"
        }
    }

    func getBatteryInfo() -> BatteryInfo {
        let device = UIDevice.current
        let level = device.batteryLevel
        let state = device.batteryState
        let isCharging = (state == .charging || state == .full)
        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

        return BatteryInfo(
            level: level >= 0 ? level : 1.0, // -1.0 means unknown
            state: state,
            isCharging: isCharging,
            isLowPowerModeEnabled: isLowPowerMode
        )
    }

    // MARK: - Storage Info

    struct StorageInfo {
        let totalSpace: Int64
        let freeSpace: Int64
        let usedSpace: Int64

        var totalSpaceGB: Double {
            Double(totalSpace) / (1024 * 1024 * 1024)
        }

        var freeSpaceGB: Double {
            Double(freeSpace) / (1024 * 1024 * 1024)
        }

        var usedSpaceGB: Double {
            Double(usedSpace) / (1024 * 1024 * 1024)
        }

        var usagePercentage: Double {
            guard totalSpace > 0 else { return 0 }
            return Double(usedSpace) / Double(totalSpace) * 100
        }

        var statusColor: String {
            switch usagePercentage {
            case 0...50: return "green"
            case 51...80: return "orange"
            default: return "red"
            }
        }

        var statusIcon: String {
            switch usagePercentage {
            case 0...50: return "internaldrive"
            case 51...80: return "internaldrive.fill"
            default: return "exclamationmark.triangle.fill"
            }
        }

        func formatBytes(_ bytes: Int64) -> String {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            formatter.allowedUnits = [.useGB, .useMB]
            return formatter.string(fromByteCount: bytes)
        }
    }

    func getStorageInfo() -> StorageInfo? {
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            return nil
        }

        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: path)

            guard let totalSpace = systemAttributes[.systemSize] as? Int64,
                  let freeSpace = systemAttributes[.systemFreeSize] as? Int64 else {
                return nil
            }

            let usedSpace = totalSpace - freeSpace

            return StorageInfo(
                totalSpace: totalSpace,
                freeSpace: freeSpace,
                usedSpace: usedSpace
            )
        } catch {
            print("⚠️ Failed to get storage info: \(error)")
            return nil
        }
    }

    // MARK: - Device Info

    struct DeviceInfo {
        let modelName: String
        let systemName: String
        let systemVersion: String
        let deviceName: String

        var displayName: String {
            "\(modelName) • iOS \(systemVersion)"
        }
    }

    func getDeviceInfo() -> DeviceInfo {
        let device = UIDevice.current

        return DeviceInfo(
            modelName: getDeviceModel(),
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            deviceName: device.name
        )
    }

    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)

        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        // Map identifier to readable name
        switch identifier {
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 14"
        case "iPhone15,5": return "iPhone 14 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        default:
            // Generic fallback
            if identifier.contains("iPhone") {
                return "iPhone"
            } else if identifier.contains("iPad") {
                return "iPad"
            }
            return identifier
        }
    }

    // MARK: - iCloud Status

    struct iCloudInfo {
        let isAvailable: Bool
        let accountStatus: String

        var statusIcon: String {
            isAvailable ? "icloud.fill" : "icloud.slash"
        }

        var statusColor: String {
            isAvailable ? "blue" : "gray"
        }

        var statusText: String {
            isAvailable ? "Connected" : "Not Available"
        }
    }

    func getiCloudInfo() -> iCloudInfo {
        let fileManager = FileManager.default
        let isAvailable = fileManager.ubiquityIdentityToken != nil

        return iCloudInfo(
            isAvailable: isAvailable,
            accountStatus: isAvailable ? "Signed In" : "Not Signed In"
        )
    }

    // MARK: - Safari Cache Warning

    struct SafariCacheInfo {
        let estimatedCacheSize: String
        let recommendation: String

        var icon: String {
            "safari"
        }

        var color: String {
            "blue"
        }
    }

    func getSafariCacheInfo() -> SafariCacheInfo {
        // Note: iOS doesn't allow direct access to Safari cache
        // We can only provide guidance to the user

        return SafariCacheInfo(
            estimatedCacheSize: "Unknown",
            recommendation: "Clear Safari cache in Settings > Safari > Clear History and Website Data"
        )
    }

    // MARK: - App Storage Info

    struct AppStorageInfo {
        let appName: String
        let estimatedSize: Int64

        var sizeGB: Double {
            Double(estimatedSize) / (1024 * 1024 * 1024)
        }

        var formattedSize: String {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return formatter.string(fromByteCount: estimatedSize)
        }
    }

    func getTopAppsStorageInfo() -> [AppStorageInfo] {
        // Note: iOS doesn't allow direct access to other apps' storage
        // We can only show guidance or our own app's usage

        // For now, return placeholder data suggesting user to check Settings
        return []
    }

    // MARK: - System Health Score

    struct SystemHealthScore {
        let batteryHealth: Int // 0-100
        let storageHealth: Int // 0-100
        let overallScore: Int // 0-100

        var grade: String {
            switch overallScore {
            case 90...100: return "A"
            case 80...89: return "B"
            case 70...79: return "C"
            case 60...69: return "D"
            default: return "F"
            }
        }

        var statusColor: String {
            switch overallScore {
            case 80...100: return "green"
            case 60...79: return "orange"
            default: return "red"
            }
        }

        var statusIcon: String {
            switch overallScore {
            case 80...100: return "checkmark.shield.fill"
            case 60...79: return "exclamationmark.shield.fill"
            default: return "xmark.shield.fill"
            }
        }
    }

    func calculateSystemHealth() -> SystemHealthScore {
        let battery = getBatteryInfo()
        let storage = getStorageInfo()

        // Battery health (0-100)
        let batteryHealth = Int(battery.level * 100)

        // Storage health (100 - usage percentage)
        let storageHealth = storage != nil ? Int(100 - storage!.usagePercentage) : 50

        // Overall score (weighted average)
        let overall = Int((Double(batteryHealth) * 0.3) + (Double(storageHealth) * 0.7))

        return SystemHealthScore(
            batteryHealth: batteryHealth,
            storageHealth: storageHealth,
            overallScore: overall
        )
    }
}
