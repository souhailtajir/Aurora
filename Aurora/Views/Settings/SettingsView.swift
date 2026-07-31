//
//  SettingsView.swift
//  Aurora
//
//  Created by souhail on 12/18/25.
//

import SwiftUI

struct SettingsView: View {
  @Environment(UserProfileStore.self) private var userProfileStore
  @Environment(TaskStore.self) private var taskStore
  @State private var showingBirthDatePicker = false
  @State private var showingResetAlert = false

  private var totalCompleted: Int {
    taskStore.tasks.filter { $0.isCompleted }.count
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: 20) {
        // Hero Profile Section
        HeroProfileView(
          profile: userProfileStore.profile,
          onEdit: { showingBirthDatePicker = true }
        )

        // General
        SettingsSection(title: "General") {
          VStack(spacing: 0) {
            NavigationLink(value: SettingsDestination.appearance) {
              SettingsRow(
                icon: "paintbrush.fill",
                iconColor: .blue,
                title: "Appearance",
                value: "System"
              )
            }
            .buttonStyle(.plain)

            CustomDivider()

            PickerRow(
              icon: "sparkles",
              iconColor: .purple,
              title: "Celestial Mode",
              selection: Binding(
                get: { userProfileStore.profile.celestialDisplayMode },
                set: { userProfileStore.updateCelestialDisplayMode($0) }
              )
            )

            CustomDivider()

            HStack(spacing: 12) {
              Image(systemName: "calendar")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.orange)

              Text("Week Starts on Monday")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)

              Spacer()

              Toggle(
                "",
                isOn: Binding(
                  get: { taskStore.weekStartsOnMonday },
                  set: {
                    taskStore.weekStartsOnMonday = $0
                    HapticService.shared.selection()
                  }
                )
              )
              .tint(Theme.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
          }
          .glassEffect()
        }

        // Sounds & Haptics
        SettingsSection(title: "Sounds & Haptics") {
          VStack(spacing: 0) {
            ToggleRow(
              icon: "speaker.wave.2.fill",
              iconColor: .pink,
              title: "Completion Sounds",
              isOn: Binding(
                get: { taskStore.completionSoundsEnabled },
                set: {
                  taskStore.completionSoundsEnabled = $0
                  HapticService.shared.selection()
                }
              )
            )

            CustomDivider()

            ToggleRow(
              icon: "iphone.radiowaves.left.and.right",
              iconColor: .orange,
              title: "Haptic Feedback",
              isOn: Binding(
                get: { taskStore.hapticFeedbackEnabled },
                set: {
                  taskStore.hapticFeedbackEnabled = $0
                  if $0 {
                    HapticService.shared.impact(.medium)
                  }
                }
              )
            )
          }
          .glassEffect(.regular)
        }

        // Journal
        SettingsSection(title: "Journal") {
          VStack(spacing: 0) {
            SettingsRow(
              icon: "text.book.closed.fill",
              iconColor: Theme.primary,
              title: "Default Theme",
              value: "System",
              showChevron: false
            )

            CustomDivider()

            SettingsRow(
              icon: "sparkles.rectangle.stack",
              iconColor: .cyan,
              title: "Journaling Suggestions",
              value: "Enabled",
              showChevron: false
            )
          }
          .glassEffect(.regular)
        }

        // Notifications
        SettingsSection(title: "Notifications") {
          VStack(spacing: 0) {
            NavigationLink(value: SettingsDestination.notifications) {
              SettingsRow(
                icon: "bell.badge.fill",
                iconColor: .red,
                title: "Notifications",
                value: "Manage"
              )
            }
            .buttonStyle(.plain)
          }
          .glassEffect(.regular)
        }

        // Privacy & Security
        SettingsSection(title: "Privacy & Security") {
          VStack(spacing: 0) {
            SettingsRow(
              icon: "faceid",
              iconColor: .green,
              title: "Journal Lock",
              value: "Face ID",
              showChevron: false
            )

            CustomDivider()

            Button {
              if let url = URL(string: "https://example.com/privacy") {
                UIApplication.shared.open(url)
              }
            } label: {
              SettingsRow(
                icon: "hand.raised.fill",
                iconColor: .mint,
                title: "Privacy Policy",
                value: ""
              )
            }
            .buttonStyle(.plain)
          }
          .glassEffect(.regular)
        }

        // Data & Storage
        SettingsSection(title: "Data & Storage") {
          VStack(spacing: 0) {
            SettingsRow(
              icon: "icloud.fill",
              iconColor: .cyan,
              title: "iCloud Sync",
              value: "On",
              showChevron: false
            )

            CustomDivider()

            SettingsRow(
              icon: "externaldrive.fill",
              iconColor: .indigo,
              title: "Storage Used",
              value: "\(taskStore.tasks.count) items",
              showChevron: false
            )
          }
          .glassEffect(.regular)
        }

        // About
        SettingsSection(title: "About") {
          VStack(spacing: 0) {
            SettingsRow(
              icon: "info.circle.fill",
              iconColor: .gray,
              title: "Version",
              value: "1.0.0",
              showChevron: false
            )

            CustomDivider()

            Button {
              if let url = URL(string: "https://example.com/terms") {
                UIApplication.shared.open(url)
              }
            } label: {
              SettingsRow(
                icon: "doc.text.fill",
                iconColor: .secondary,
                title: "Terms of Service",
                value: ""
              )
            }
            .buttonStyle(.plain)
          }
          .glassEffect(.regular)
        }

        // Danger Zone
        SettingsSection(title: "Danger Zone") {
          VStack(spacing: 0) {
            Button {
              HapticService.shared.notification(.warning)
              taskStore.clearCompletedTasks()
            } label: {
              SettingsRow(
                icon: "trash.fill",
                iconColor: .red,
                title: "Clear Completed Tasks",
                value: "\(totalCompleted)"
              )
            }
            .buttonStyle(.plain)

            CustomDivider()

            Button {
              HapticService.shared.notification(.warning)
              showingResetAlert = true
            } label: {
              SettingsRow(
                icon: "arrow.counterclockwise",
                iconColor: .red,
                title: "Reset All Settings",
                value: ""
              )
            }
            .buttonStyle(.plain)
          }
          .glassEffect(.regular)
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 20)
      .padding(.bottom, 100)
    }
    .background(Color.clear.auroraBackground())
    .navigationTitle("Settings")
    .toolbarTitleDisplayMode(.inlineLarge)
    .safeAreaPadding(.top, 8)
    .toolbar(.hidden, for: .tabBar)
    .sheet(isPresented: $showingBirthDatePicker) {
      BirthDatePickerView(
        userProfileStore: userProfileStore, isPresented: $showingBirthDatePicker)
    }
    .alert("Reset All Settings?", isPresented: $showingResetAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Reset", role: .destructive) {
        taskStore.hapticFeedbackEnabled = true
        taskStore.completionSoundsEnabled = true
        HapticService.shared.notification(.success)
      }
    } message: {
      Text("This will reset all settings to their default values. Your tasks will not be affected.")
    }
    .navigationDestination(for: SettingsDestination.self) { destination in
      switch destination {
      case .appearance:
        AppearanceSettingsView()
      case .notifications:
        NotificationSettingsView()
      }
    }
  }
}

// MARK: - Toggle Row Component

struct ToggleRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  @Binding var isOn: Bool

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(iconColor)

      Text(title)
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.primary)

      Spacer()

      Toggle("", isOn: $isOn)
        .tint(Theme.secondary)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
  }
}

// MARK: - Settings Destination

enum SettingsDestination: Hashable {
  case appearance
  case notifications
}

// MARK: - Components

struct HeroProfileView: View {
  let profile: UserProfile
  let onEdit: () -> Void

  var body: some View {
    HStack(spacing: 20) {
      // Info Column
      VStack(alignment: .leading, spacing: 8) {
        VStack(alignment: .leading, spacing: 4) {
          Text(profile.name)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)

          Text(profile.email)
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }

        // Zodiac Info
        HStack(spacing: 6) {
          Image(systemName: profile.zodiacSign.symbol)
            .font(.system(size: 14))
            .foregroundStyle(Theme.primary)

          Text(
            "\(profile.zodiacSign.rawValue) • \(profile.birthDate?.formatted(.dateTime.day().month(.abbreviated)) ?? "Set Date")"
          )
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(Theme.secondary.opacity(0.1))
        .clipShape(Capsule())

        Button(action: onEdit) {
          Text("Edit Profile")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.secondary)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
      }

      Spacer()

      // Avatar with gradient ring
      ZStack {
        // Animated gradient ring
        Circle()
          .strokeBorder(
            AngularGradient(
              colors: [Theme.primary, Theme.secondary, .cyan, Theme.primary],
              center: .center
            ),
            lineWidth: 3
          )
          .frame(width: 90, height: 90)

        Circle()
          .fill(
            LinearGradient(
              colors: [Theme.secondary, Theme.primary],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 80, height: 80)
          .overlay(
            Text(profile.name.prefix(1))
              .font(.system(size: 34, weight: .bold, design: .rounded))
              .foregroundStyle(.white)
          )
      }
      .shadow(color: Theme.secondary.opacity(0.3), radius: 16, x: 0, y: 8)
    }
    .frame(maxWidth: .infinity)
    .padding(24)
    .glassEffect(.regular)
  }
}

struct SettingsSection<Content: View>: View {
  let title: String
  let content: Content

  init(title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .padding(.leading, 8)

      content
    }
  }
}

struct SettingsRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  let value: String
  var showChevron: Bool = true

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(iconColor)

      Text(title)
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.primary)

      Spacer()

      if !value.isEmpty {
        Text(value)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.secondary)
      }

      if showChevron {
        Image(systemName: "chevron.right")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.tertiary)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
    .contentShape(Rectangle())
  }
}

struct PickerRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  @Binding var selection: CelestialDisplayMode

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(iconColor)

      Text(title)
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.primary)

      Spacer()

      Picker("", selection: $selection) {
        Text("Planet").tag(CelestialDisplayMode.zodiacPlanet)
        Text("Moon").tag(CelestialDisplayMode.moonPhase)
      }
      .pickerStyle(.menu)
      .tint(.secondary)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 14)
  }
}

struct CustomDivider: View {
  var body: some View {
    Divider()
      .padding(.leading, 50)
  }
}

// MARK: - Appearance Settings View

struct AppearanceSettingsView: View {
  @State private var selectedAppearance = "System"

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 16) {
        Text("APPEARANCE MODE")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.secondary)
          .padding(.leading, 8)

        VStack(spacing: 0) {
          ForEach(["Light", "Dark", "System"], id: \.self) { option in
            Button {
              selectedAppearance = option
              HapticService.shared.selection()
            } label: {
              HStack(spacing: 12) {
                Image(systemName: iconForAppearance(option))
                  .font(.system(size: 18, weight: .semibold))
                  .foregroundStyle(Theme.secondary)

                Text(option)
                  .font(.system(size: 16, weight: .medium))
                  .foregroundStyle(.primary)

                Spacer()

                if selectedAppearance == option {
                  Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
                }
              }
              .padding(.horizontal, 20)
              .padding(.vertical, 14)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if option != "System" {
              Divider()
                .padding(.leading, 50)
            }
          }
        }
        .glassEffect(.regular)
      }
      .padding(.horizontal, 16)
      .padding(.top, 20)
      .padding(.bottom, 100)
    }
    .background(Color.clear.auroraBackground())
    .navigationTitle("Appearance")
    .toolbarTitleDisplayMode(.inlineLarge)
    .safeAreaPadding(.top, 8)
    .toolbar(.hidden, for: .tabBar)
  }

  private func iconForAppearance(_ option: String) -> String {
    switch option {
    case "Light": return "sun.max.fill"
    case "Dark": return "moon.fill"
    default: return "circle.lefthalf.filled"
    }
  }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
  @State private var notificationsEnabled = true
  @State private var dailyReminders = true
  @State private var taskAlerts = true

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 24) {
        // Main Toggle
        VStack(spacing: 0) {
          HStack(spacing: 12) {
            Image(systemName: "bell.fill")
              .font(.system(size: 18, weight: .semibold))
              .foregroundStyle(.red)

            Text("Enable Notifications")
              .font(.system(size: 16, weight: .medium))
              .foregroundStyle(.primary)

            Spacer()

            Toggle("", isOn: $notificationsEnabled)
              .tint(Theme.secondary)
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 14)
        }
        .glassEffect(.regular)

        // Notification Types
        VStack(alignment: .leading, spacing: 10) {
          Text("NOTIFICATION TYPES")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.leading, 8)

          VStack(spacing: 0) {
            HStack(spacing: 12) {
              Image(systemName: "clock.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.secondary)

              Text("Daily Reminders")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(notificationsEnabled ? .primary : .secondary)

              Spacer()

              Toggle("", isOn: $dailyReminders)
                .tint(Theme.secondary)
                .disabled(!notificationsEnabled)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()
              .padding(.leading, 50)

            HStack(spacing: 12) {
              Image(systemName: "checklist")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.secondary)

              Text("Task Alerts")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(notificationsEnabled ? .primary : .secondary)

              Spacer()

              Toggle("", isOn: $taskAlerts)
                .tint(Theme.secondary)
                .disabled(!notificationsEnabled)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
          }
          .glassEffect(.regular)
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 20)
      .padding(.bottom, 100)
    }
    .background(Color.clear.auroraBackground())
    .navigationTitle("Notifications")
    .toolbarTitleDisplayMode(.inlineLarge)
    .safeAreaPadding(.top, 8)
    .toolbar(.hidden, for: .tabBar)
  }
}

#Preview {
  SettingsView()
    .environment(UserProfileStore())
}
