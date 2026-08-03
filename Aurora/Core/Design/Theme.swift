//
//  Theme.swift
//  Aurora
//

import SwiftUI
@MainActor
enum Theme {
  static let primary = Color(red: 0.48, green: 0.38, blue: 0.95)
  static let secondary = Color(red: 0.62, green: 0.48, blue: 0.98)
  static let tint = Color(red: 0.48, green: 0.38, blue: 0.95)

  // Background Colors
  static let backgroundTop = Color(red: 0.85, green: 0.8, blue: 0.95)
  static let backgroundBottom = Color(red: 0.9, green: 0.85, blue: 0.95)

  // Gradients & Accents
  static let insightsGradientTop = Color(hex: "6252C4")
  static let insightsGradientBottom = Color(hex: "3B3885")

  static var auroraBackground: some View {
    AuroraBackgroundView()
  }

  static func categoryColor(for category: TaskCategory) -> Color {
    Color(hex: category.colorHex)
  }
}

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3:
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 255, 255, 255)
    }

    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}

extension View {
  func auroraBackground() -> some View {
    background(AuroraBackgroundView())
  }
}

struct AuroraBackgroundView: View {
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack {
      if colorScheme == .dark {
        Color(hex: "0B0A12")

        Circle()
          .fill(Theme.primary.opacity(0.18))
          .frame(width: 320, height: 320)
          .blur(radius: 90)
          .offset(x: -120, y: -200)

        Circle()
          .fill(Theme.secondary.opacity(0.15))
          .frame(width: 280, height: 280)
          .blur(radius: 80)
          .offset(x: 140, y: 180)
      } else {
        Color(hex: "F7F6FA")

        Circle()
          .fill(Color(hex: "E3D7FF").opacity(0.5))
          .frame(width: 340, height: 340)
          .blur(radius: 90)
          .offset(x: -100, y: -180)

        Circle()
          .fill(Color(hex: "D3C2FF").opacity(0.35))
          .frame(width: 300, height: 300)
          .blur(radius: 80)
          .offset(x: 120, y: 160)
      }
    }
    .ignoresSafeArea()
  }
}
