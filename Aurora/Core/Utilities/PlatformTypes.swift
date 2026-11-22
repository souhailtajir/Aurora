//
//  PlatformTypes.swift
//  Aurora
//
//  Cross-platform type aliases and helpers for iOS / macOS native support.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Platform Type Aliases

#if canImport(UIKit)
typealias PlatformImage = UIImage
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
typealias PlatformImage = NSImage
typealias PlatformColor = NSColor
#endif

// MARK: - Cross-Platform Image from Data

extension Image {
  /// Creates a SwiftUI `Image` from raw `Data` on both iOS and macOS.
  init?(data: Data) {
    #if canImport(UIKit)
    guard let uiImage = UIImage(data: data) else { return nil }
    self.init(uiImage: uiImage)
    #elseif canImport(AppKit)
    guard let nsImage = NSImage(data: data) else { return nil }
    self.init(nsImage: nsImage)
    #endif
  }
}

// MARK: - Cross-Platform URL Opener

func openURL(_ url: URL) {
  #if canImport(UIKit)
  UIApplication.shared.open(url)
  #elseif canImport(AppKit)
  NSWorkspace.shared.open(url)
  #endif
}

// MARK: - Cross-Platform Color → Hex

extension Color {
  /// Converts a `Color` to its hex string representation, cross-platform.
  func platformHex() -> String? {
    #if canImport(UIKit)
    let platformColor = UIColor(self)
    #elseif canImport(AppKit)
    let platformColor = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
    #endif

    guard let components = platformColor.cgColor.components, components.count >= 3 else {
      return nil
    }
    let r = Float(components[0])
    let g = Float(components[1])
    let b = Float(components[2])
    var a = Float(1.0)

    if components.count >= 4 {
      a = Float(components[3])
    }

    if a != Float(1.0) {
      return String(
        format: "#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255),
        lroundf(b * 255), lroundf(a * 255))
    } else {
      return String(
        format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
  }
}

// MARK: - Cross-Platform Keyboard Dismissal

/// Dismisses the software keyboard on iOS; no-op on macOS.
func dismissKeyboard() {
  #if canImport(UIKit)
  UIApplication.shared.sendAction(
    #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  #endif
}

// MARK: - Cross-Platform System Background Colors

extension Color {
  /// Grouped background, matching `UIColor.systemGroupedBackground` on iOS
  /// and `NSColor.windowBackgroundColor` on macOS.
  static var systemGroupedBackground: Color {
    #if canImport(UIKit)
    Color(uiColor: .systemGroupedBackground)
    #elseif canImport(AppKit)
    Color(nsColor: .windowBackgroundColor)
    #endif
  }

  /// Secondary grouped background.
  static var secondarySystemGroupedBackground: Color {
    #if canImport(UIKit)
    Color(uiColor: .secondarySystemGroupedBackground)
    #elseif canImport(AppKit)
    Color(nsColor: .controlBackgroundColor)
    #endif
  }
}

// MARK: - Cross-Platform Toolbar Item Placement

extension ToolbarItemPlacement {
  static var platformTopBarLeading: ToolbarItemPlacement {
    #if os(macOS)
    .navigation
    #else
    .topBarLeading
    #endif
  }

  static var platformTopBarTrailing: ToolbarItemPlacement {
    #if os(macOS)
    .primaryAction
    #else
    .topBarTrailing
    #endif
  }
}

// MARK: - Cross-Platform List Modifiers

extension View {
  @ViewBuilder
  func platformListRowSpacing(_ spacing: CGFloat) -> some View {
    #if os(iOS)
    self.listRowSpacing(spacing)
    #else
    self
    #endif
  }
}

// MARK: - Cross-Platform SceneKit Helpers

import SceneKit

#if os(macOS)
typealias SCNFloat = CGFloat
#else
typealias SCNFloat = Float
#endif

// MARK: - Transparent Window Accessor (macOS)

#if os(macOS)
struct WindowAccessor: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    DispatchQueue.main.async {
      Self.configureWindow(view.window)
    }
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    // Re-apply on updates in case the window reference changed
    Self.configureWindow(nsView.window)
  }

  private static func configureWindow(_ window: NSWindow?) {
    guard let window else { return }
    window.titlebarAppearsTransparent = true
    window.isOpaque = false
    window.backgroundColor = .clear
    window.styleMask.insert(.fullSizeContentView)
    window.isMovableByWindowBackground = true
    window.titlebarSeparatorStyle = .none
    window.minSize = NSSize(width: 900, height: 620)
  }
}
#endif





