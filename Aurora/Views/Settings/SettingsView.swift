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
  @Environment(\.horizontalSizeClass) private var sizeClass
  @State private var showingBirthDatePicker = false
  @State private var showingResetAlert = false

  private var totalCompleted: Int {
    taskStore.tasks.filter { $0.isCompleted }.count
  }

  var body: some View {
    #if os(macOS)
    macOSSettingsBody
    #else
    iOSSettingsBody
    #endif
  }

  // MARK: - macOS Settings (TabView)

  #if os(macOS)
  private var macOSSettingsBody: some View {
    TabView {
      // General Tab
      ScrollView(showsIndicators: false) {
        VStack(spacing: LayoutTokens.Spacing.xl) {
          heroSection
          generalSection
          soundsAndHapticsSection
          journalSection
          privacySection
          dataAndStorageSection
          dangerZoneSection
        }
        .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
        .padding(.vertical, LayoutTokens.Padding.sectionTop)
      }
      .background(Color.clear.auroraBackground())
      .tabItem {
        Label("General", systemImage: "gearshape")
      }

      // Notifications Tab
      NotificationSettingsView()
        .tabItem {
          Label("Notifications", systemImage: "bell.badge.fill")
        }

      // Appearance Tab
      AppearanceSettingsView()
        .tabItem {
          Label("Appearance", systemImage: "paintbrush.fill")
        }

      // About Tab
      ScrollView(showsIndicators: false) {
        VStack(spacing: LayoutTokens.Spacing.xl) {
          aboutSection
        }
        .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
        .padding(.vertical, LayoutTokens.Padding.sectionTop)
      }
      .background(Color.clear.auroraBackground())
      .tabItem {
        Label("About", systemImage: "info.circle")
      }
    }
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
  }
  #endif

  // MARK: - iOS Settings (ScrollView)

  private var iOSSettingsBody: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: LayoutTokens.Spacing.xl) {
        heroSection
        generalSection
        soundsAndHapticsSection
        journalSection
        notificationsSection
        privacySection
        dataAndStorageSection
        aboutSection
        dangerZoneSection
      }
      .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
      .padding(.top, LayoutTokens.Padding.sectionTop)
      .padding(.bottom, LayoutTokens.Padding.scrollBottom)
    }
    .background(Color.clear.auroraBackground())
    .navigationTitle("Settings")
    .toolbarTitleDisplayMode(.inlineLarge)
    .safeAreaPadding(.top, 8)
    #if os(iOS)
    .toolbar(.hidden, for: .tabBar)
    #endif
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

// MARK: - Section Computed Properties

extension SettingsView {

  private var heroSection: some View {
    HeroProfileView(
      profile: userProfileStore.profile,
      onEdit: { showingBirthDatePicker = true }
    )
  }

  private var generalSection: some View {
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

        ToggleRow(
          icon: "calendar",
          iconColor: .orange,
          title: "Week Starts on Monday",
          isOn: Binding(
            get: { taskStore.weekStartsOnMonday },
            set: {
              taskStore.weekStartsOnMonday = $0
              HapticService.shared.selection()
            }
          )
        )
      }
      .glassEffect()
    }
  }

  private var soundsAndHapticsSection: some View {
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
  }

  private var journalSection: some View {
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
  }

  private var notificationsSection: some View {
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
  }

  private var privacySection: some View {
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
            openURL(url)
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
  }

  private var dataAndStorageSection: some View {
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
  }

  private var aboutSection: some View {
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
            openURL(url)
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
  }

  private var dangerZoneSection: some View {
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
}

#Preview {
  SettingsView()
    .environment(UserProfileStore())
}
