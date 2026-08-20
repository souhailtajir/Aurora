//
//  AppearanceSettingsView.swift
//  Aurora
//
//  Appearance mode selection sub-view (Light / Dark / System).
//

import SwiftUI

// MARK: - Settings Destination

enum SettingsDestination: Hashable {
  case appearance
  case notifications
}

// MARK: - Appearance Settings View

struct AppearanceSettingsView: View {
  @State private var selectedAppearance = "System"
  @Environment(\.horizontalSizeClass) private var sizeClass

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: LayoutTokens.Spacing.lg) {
        Text("APPEARANCE MODE")
          .font(.system(size: LayoutTokens.Typography.footnote, weight: .semibold))
          .foregroundStyle(.secondary)
          .padding(.leading, LayoutTokens.Padding.sectionHeaderLeading)

        VStack(spacing: 0) {
          ForEach(["Light", "Dark", "System"], id: \.self) { option in
            Button {
              selectedAppearance = option
              HapticService.shared.selection()
            } label: {
              HStack(spacing: LayoutTokens.Spacing.md) {
                Image(systemName: iconForAppearance(option))
                  .font(.system(size: LayoutTokens.IconSize.md, weight: .semibold))
                  .foregroundStyle(Theme.secondary)
                  .frame(width: LayoutTokens.IconSize.rowFrame)

                Text(option)
                  .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
                  .foregroundStyle(.primary)

                Spacer()

                if selectedAppearance == option {
                  Image(systemName: "checkmark")
                    .font(.system(size: LayoutTokens.Typography.body, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
                }
              }
              .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
              .padding(.vertical, LayoutTokens.Padding.rowVertical)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if option != "System" {
              Divider()
                .padding(.leading, LayoutTokens.Padding.screenHorizontal(for: sizeClass) + LayoutTokens.IconSize.rowFrame + LayoutTokens.Spacing.md)
            }
          }
        }
        .glassEffect(.regular)
      }
      .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
      .padding(.top, LayoutTokens.Padding.sectionTop)
      .padding(.bottom, LayoutTokens.Padding.scrollBottom)
    }
    .background(Color.clear.auroraBackground())
    .navigationTitle("Appearance")
    .toolbarTitleDisplayMode(.inlineLarge)
    .safeAreaPadding(.top, 8)
    #if os(iOS)
    .toolbar(.hidden, for: .tabBar)
    #endif
  }

  private func iconForAppearance(_ option: String) -> String {
    switch option {
    case "Light": return "sun.max.fill"
    case "Dark": return "moon.fill"
    default: return "circle.lefthalf.filled"
    }
  }
}
