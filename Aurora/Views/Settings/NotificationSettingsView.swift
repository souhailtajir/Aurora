//
//  NotificationSettingsView.swift
//  Aurora
//
//  Notification preferences sub-view.
//

import SwiftUI

struct NotificationSettingsView: View {
  @State private var notificationsEnabled = true
  @State private var dailyReminders = true
  @State private var taskAlerts = true
  @Environment(\.horizontalSizeClass) private var sizeClass

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: LayoutTokens.Spacing.xxl) {
        // Main Toggle
        VStack(spacing: 0) {
          ToggleRow(
            icon: "bell.fill",
            iconColor: .red,
            title: "Enable Notifications",
            isOn: $notificationsEnabled
          )
        }
        .glassEffect(.regular)

        // Notification Types
        VStack(alignment: .leading, spacing: LayoutTokens.Spacing.sm) {
          Text("NOTIFICATION TYPES")
            .font(.system(size: LayoutTokens.Typography.footnote, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, LayoutTokens.Padding.sectionHeaderLeading)

          VStack(spacing: 0) {
            ToggleRow(
              icon: "clock.fill",
              iconColor: Theme.secondary,
              title: "Daily Reminders",
              isOn: $dailyReminders
            )
            .disabled(!notificationsEnabled)
            .foregroundStyle(notificationsEnabled ? .primary : .secondary)

            CustomDivider()

            ToggleRow(
              icon: "checklist",
              iconColor: Theme.secondary,
              title: "Task Alerts",
              isOn: $taskAlerts
            )
            .disabled(!notificationsEnabled)
            .foregroundStyle(notificationsEnabled ? .primary : .secondary)
          }
          .glassEffect(.regular)
        }
      }
      .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
      .padding(.top, LayoutTokens.Padding.sectionTop)
      .padding(.bottom, LayoutTokens.Padding.scrollBottom)
    }
    .background(Color.clear.auroraBackground())
    .navigationTitle("Notifications")
    .toolbarTitleDisplayMode(.inlineLarge)
    .safeAreaPadding(.top, 8)
    .toolbar(.hidden, for: .tabBar)
  }
}
