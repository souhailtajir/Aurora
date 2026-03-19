//
//  AppDelegate.swift
//  Aurora
//
//  Created by souhail on 3/19/26.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {

  /// Set by AuroraApp immediately after init so the delegate can fire triggers.
  var taskStore: TaskStore?

  // Called when the user taps a home-screen quick action while the app is already running.
  func application(
    _ application: UIApplication,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    handle(shortcutItem)
    completionHandler(true)
  }


  // MARK: - Private

  private func handle(_ shortcutItem: UIApplicationShortcutItem) {
    guard let store = taskStore else { return }

    if shortcutItem.type.hasSuffix(".addTask") {
      store.quickAction = .addTask
    } else if shortcutItem.type.hasSuffix(".addJournal") {
      store.quickAction = .addJournal
    }
  }
}
