//
//  SettingsRowComponents.swift
//  Aurora
//
//  Reusable row-level components for the Settings UI.
//

import SwiftUI

// MARK: - Layout Constants

// Layout variables are now sourced directly from LayoutTokens.

// MARK: - Settings Section

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
        .font(.system(size: LayoutTokens.Typography.footnote, weight: .semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .padding(.leading, LayoutTokens.Padding.sectionHeaderLeading)

      content
    }
  }
}

// MARK: - Settings Row

struct SettingsRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  let value: String
  var showChevron: Bool = true
  @Environment(\.horizontalSizeClass) private var sizeClass

  var body: some View {
    HStack(spacing: LayoutTokens.Spacing.md) {
      Image(systemName: icon)
        .font(.system(size: LayoutTokens.IconSize.md, weight: .semibold))
        .foregroundStyle(iconColor)
        .frame(width: LayoutTokens.IconSize.rowFrame)

      Text(title)
        .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
        .foregroundStyle(.primary)

      Spacer()

      if !value.isEmpty {
        Text(value)
          .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
          .foregroundStyle(.secondary)
      }

      if showChevron {
        Image(systemName: "chevron.right")
          .font(.system(size: LayoutTokens.Typography.caption, weight: .semibold))
          .foregroundStyle(.tertiary)
      }
    }
    .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
    .padding(.vertical, LayoutTokens.Padding.rowVertical)
    .contentShape(Rectangle())
  }
}

// MARK: - Toggle Row

struct ToggleRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  @Binding var isOn: Bool
  @Environment(\.horizontalSizeClass) private var sizeClass

  var body: some View {
    HStack(spacing: LayoutTokens.Spacing.md) {
      Image(systemName: icon)
        .font(.system(size: LayoutTokens.IconSize.md, weight: .semibold))
        .foregroundStyle(iconColor)
        .frame(width: LayoutTokens.IconSize.rowFrame)

      Text(title)
        .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
        .foregroundStyle(.primary)

      Spacer()

      Toggle("", isOn: $isOn)
        .tint(Theme.secondary)
    }
    .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
    .padding(.vertical, LayoutTokens.Padding.rowVertical)
  }
}

// MARK: - Picker Row

struct PickerRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  @Binding var selection: CelestialDisplayMode
  @Environment(\.horizontalSizeClass) private var sizeClass

  var body: some View {
    HStack(spacing: LayoutTokens.Spacing.md) {
      Image(systemName: icon)
        .font(.system(size: LayoutTokens.IconSize.md, weight: .semibold))
        .foregroundStyle(iconColor)
        .frame(width: LayoutTokens.IconSize.rowFrame)

      Text(title)
        .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
        .foregroundStyle(.primary)

      Spacer()

      Picker("", selection: $selection) {
        Text("Planet").tag(CelestialDisplayMode.zodiacPlanet)
        Text("Moon").tag(CelestialDisplayMode.moonPhase)
      }
      .pickerStyle(.menu)
      .tint(.secondary)
    }
    .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
    .padding(.vertical, LayoutTokens.Padding.rowVertical)
  }
}

// MARK: - Custom Divider

struct CustomDivider: View {
  @Environment(\.horizontalSizeClass) private var sizeClass

  var body: some View {
    Divider()
      .padding(.leading, LayoutTokens.Padding.screenHorizontal(for: sizeClass) + LayoutTokens.IconSize.rowFrame + LayoutTokens.Spacing.md)
  }
}
