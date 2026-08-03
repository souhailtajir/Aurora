//
//  HapticService.swift
//  Aurora
//

import UIKit

@MainActor
@Observable
final class HapticService {
  static let shared = HapticService()

  // MARK: - Generators (pre-prepared for low latency)

  private let lightImpact = UIImpactFeedbackGenerator(style: .light)
  private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
  private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
  private let softImpact = UIImpactFeedbackGenerator(style: .soft)
  private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
  private let notificationGenerator = UINotificationFeedbackGenerator()
  private let selectionGenerator = UISelectionFeedbackGenerator()

  private init() {
    prepare()
  }

  // MARK: - Enable Check

  private var isEnabled: Bool {
    UserDefaults.standard.data(forKey: "AppSettings")
      .flatMap { try? JSONDecoder().decode(AppSettings.self, from: $0) }
      .map(\.hapticFeedbackEnabled) ?? true
  }

  // MARK: - Prepare

  func prepare() {
    lightImpact.prepare()
    mediumImpact.prepare()
    heavyImpact.prepare()
    softImpact.prepare()
    rigidImpact.prepare()
    notificationGenerator.prepare()
    selectionGenerator.prepare()
  }

  // MARK: - Impact

  func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    guard isEnabled else { return }
    switch style {
    case .light: lightImpact.impactOccurred()
    case .medium: mediumImpact.impactOccurred()
    case .heavy: heavyImpact.impactOccurred()
    case .soft: softImpact.impactOccurred()
    case .rigid: rigidImpact.impactOccurred()
    @unknown default: mediumImpact.impactOccurred()
    }
  }

  // MARK: - Notification

  func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
    guard isEnabled else { return }
    notificationGenerator.notificationOccurred(type)
  }

  // MARK: - Selection

  func selection() {
    guard isEnabled else { return }
    selectionGenerator.selectionChanged()
  }
}
