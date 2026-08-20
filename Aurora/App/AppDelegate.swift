//
//  AppDelegate.swift
//  Aurora
//
//  Created by souhail on 3/19/26.
//

import SwiftUI

@Observable
final class QuickActionManager {
  static let shared = QuickActionManager()
  var action: TaskStore.QuickAction = .none
}

#if os(iOS)
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    config.delegateClass = SceneDelegate.self
    return config
  }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  
  // Warm launch
  func windowScene(
    _ windowScene: UIWindowScene,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    handle(shortcutItem)
    completionHandler(true)
  }

  // Cold launch
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let shortcutItem = connectionOptions.shortcutItem {
      // Delay allows the UI to render before we attempt to pop sheets
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.handle(shortcutItem)
      }
    }
  }

  private func handle(_ item: UIApplicationShortcutItem) {
    if item.type.hasSuffix(".addTask") {
      QuickActionManager.shared.action = .addTask
    }
    else if item.type.hasSuffix(".addJournal") {
      QuickActionManager.shared.action = .addJournal
    }  
    else if item.type.hasSuffix(".openCalendar") {
      QuickActionManager.shared.action = .openCalendar
    } 
  }
}
#endif
