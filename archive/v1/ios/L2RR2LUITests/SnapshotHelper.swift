//
//  SnapshotHelper.swift
//  L2RR2L
//
//  Screenshot helper for fastlane snapshot
//

import Foundation
import XCTest

var deviceLanguage = ""
var locale = ""

func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
    Snapshot.setupSnapshot(app, waitForAnimations: waitForAnimations)
}

func snapshot(_ name: String, waitForLoadingIndicator: Bool = true) {
    if waitForLoadingIndicator {
        Snapshot.snapshot(name, timeWaitingForIdle: 20)
    } else {
        Snapshot.snapshot(name, timeWaitingForIdle: 0)
    }
}

enum Snapshot {
    static var app: XCUIApplication?
    static var waitForAnimations = true
    static var cacheDirectory: URL?
    static var screenshotsDirectory: URL? {
        return cacheDirectory?.appendingPathComponent("screenshots", isDirectory: true)
    }

    static func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool = true) {
        Snapshot.app = app
        Snapshot.waitForAnimations = waitForAnimations

        do {
            let cacheDir = try getCacheDirectory()
            Snapshot.cacheDirectory = cacheDir
            setLanguage(app)
            setLocale(app)
            setLaunchArguments(app)
        } catch {
            NSLog("Snapshot: Error setting up snapshot: \(error)")
        }
    }

    static func setLanguage(_ app: XCUIApplication) {
        guard let cacheDirectory = self.cacheDirectory else {
            NSLog("Snapshot: Cache directory not set")
            return
        }

        let path = cacheDirectory.appendingPathComponent("language.txt")

        do {
            let trimCharacterSet = CharacterSet.whitespacesAndNewlines
            deviceLanguage = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacterSet)
            app.launchArguments += ["-AppleLanguages", "(\(deviceLanguage))"]
        } catch {
            NSLog("Snapshot: Couldn't find language.txt at \(path.path)")
        }
    }

    static func setLocale(_ app: XCUIApplication) {
        guard let cacheDirectory = self.cacheDirectory else {
            NSLog("Snapshot: Cache directory not set")
            return
        }

        let path = cacheDirectory.appendingPathComponent("locale.txt")

        do {
            let trimCharacterSet = CharacterSet.whitespacesAndNewlines
            locale = try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: trimCharacterSet)
        } catch {
            NSLog("Snapshot: Couldn't find locale.txt at \(path.path)")
        }

        if locale.isEmpty && !deviceLanguage.isEmpty {
            locale = Locale(identifier: deviceLanguage).identifier
        }

        if !locale.isEmpty {
            app.launchArguments += ["-AppleLocale", "\"\(locale)\""]
        }
    }

    static func setLaunchArguments(_ app: XCUIApplication) {
        guard let cacheDirectory = self.cacheDirectory else {
            NSLog("Snapshot: Cache directory not set")
            return
        }

        let path = cacheDirectory.appendingPathComponent("snapshot-launch_arguments.txt")
        app.launchArguments += ["-FASTLANE_SNAPSHOT", "YES", "-ui_testing"]

        do {
            let launchArguments = try String(contentsOf: path, encoding: .utf8)
            let lines = launchArguments.components(separatedBy: .newlines)
            for line in lines where !line.isEmpty {
                app.launchArguments.append(line)
            }
        } catch {
            NSLog("Snapshot: Couldn't find launch arguments file at \(path.path)")
        }
    }

    static func snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 20) {
        if timeout > 0 {
            waitForLoadingIndicatorToDisappear(within: timeout)
        }

        NSLog("Snapshot: Taking screenshot '\(name)'")

        sleep(1)

        guard let app = self.app else {
            NSLog("Snapshot: App not set. Call setupSnapshot before snapshot.")
            return
        }

        let screenshot = app.windows.firstMatch.screenshot()

        guard let simulator = ProcessInfo().environment["SIMULATOR_DEVICE_NAME"],
              let screenshotsDir = screenshotsDirectory else {
            NSLog("Snapshot: Unable to determine simulator or screenshots directory")
            return
        }

        let path = screenshotsDir.appendingPathComponent("\(simulator)-\(name).png")

        do {
            try FileManager.default.createDirectory(at: screenshotsDir, withIntermediateDirectories: true, attributes: nil)
            try screenshot.pngRepresentation.write(to: path)
            NSLog("Snapshot: Saved screenshot to \(path.path)")
        } catch {
            NSLog("Snapshot: Error saving screenshot: \(error)")
        }
    }

    static func waitForLoadingIndicatorToDisappear(within timeout: TimeInterval) {
        guard let app = self.app else { return }

        let networkLoadingIndicator = app.otherElements.deviceStatusBars.networkLoadingIndicators.element
        let exists = networkLoadingIndicator.waitForNonExistence(timeout: timeout)

        if exists {
            NSLog("Snapshot: Loading indicator still visible after \(timeout) seconds")
        }
    }

    static func getCacheDirectory() throws -> URL {
        let cachePath = "Library/Caches/tools.fastlane"

        // First, try to find the app's cache directory using NSSearchPathForDirectoriesInDomains
        guard let simulatorHostHome = ProcessInfo().environment["SIMULATOR_HOST_HOME"] ??
                                      ProcessInfo().environment["HOME"] else {
            throw NSError(domain: "Snapshot", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to determine home directory"])
        }

        let url = URL(fileURLWithPath: simulatorHostHome).appendingPathComponent(cachePath)
        return url
    }
}

private extension XCUIElementAttributes {
    var isNetworkLoadingIndicator: Bool {
        if hasAllowListedIdentifier { return false }

        let hasOldLoadingIndicatorSize = frame.size == CGSize(width: 10, height: 20)
        let hasNewLoadingIndicatorSize = frame.size.width.isBetween(46, and: 47) && frame.size.height.isBetween(2, and: 3)

        return hasOldLoadingIndicatorSize || hasNewLoadingIndicatorSize
    }

    var hasAllowListedIdentifier: Bool {
        let dominated = ["Waiting for network", "data detectors", "No signal", "Not charging"]
        return dominated.contains { self.identifier.contains($0) }
    }
}

private extension XCUIElementQuery {
    var networkLoadingIndicators: XCUIElementQuery {
        let isNetworkLoadingIndicator = NSPredicate { evaluatedObject, _ in
            guard let element = evaluatedObject as? XCUIElementAttributes else { return false }
            return element.isNetworkLoadingIndicator
        }

        return self.containing(isNetworkLoadingIndicator)
    }

    var deviceStatusBars: XCUIElementQuery {
        let isStatusBar = NSPredicate { evaluatedObject, _ in
            guard let element = evaluatedObject as? XCUIElementAttributes else { return false }
            return element.isStatusBar
        }

        return self.containing(isStatusBar)
    }
}

private extension XCUIElementAttributes {
    var isStatusBar: Bool {
        return elementType == .statusBar
    }
}

private extension CGFloat {
    func isBetween(_ a: CGFloat, and b: CGFloat) -> Bool {
        return a...b ~= self
    }
}

private extension XCUIElement {
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let timeStart = Date().timeIntervalSince1970

        while Date().timeIntervalSince1970 <= timeStart + timeout {
            if !exists { return true }
            Thread.sleep(forTimeInterval: 0.1)
        }

        return false
    }
}
