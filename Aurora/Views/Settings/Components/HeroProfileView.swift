//
//  HeroProfileView.swift
//  Aurora
//
//  Profile hero card displayed at the top of the Settings screen.
//

import SwiftUI

struct HeroProfileView: View {
  let profile: UserProfile
  let onEdit: () -> Void
  @Environment(\.horizontalSizeClass) private var sizeClass

  var body: some View {
    HStack(spacing: LayoutTokens.Spacing.xl) {
      // Info Column
      VStack(alignment: .leading, spacing: LayoutTokens.Spacing.sm) {
        VStack(alignment: .leading, spacing: LayoutTokens.Spacing.xs) {
          Text(profile.name)
            .font(.system(size: LayoutTokens.Typography.title1, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)

          Text(profile.email)
            .font(.system(size: LayoutTokens.Typography.callout))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }

        // Zodiac Info
        HStack(spacing: LayoutTokens.Spacing.sm) {
          Image(systemName: profile.zodiacSign.symbol)
            .font(.system(size: LayoutTokens.Typography.subheadline))
            .foregroundStyle(Theme.primary)

          Text(
            "\(profile.zodiacSign.rawValue) • \(profile.birthDate?.formatted(.dateTime.day().month(.abbreviated)) ?? "Set Date")"
          )
          .font(.system(size: LayoutTokens.Typography.subheadline, weight: .medium))
          .foregroundStyle(.secondary)
        }
        .padding(.vertical, LayoutTokens.Spacing.xs)
        .padding(.horizontal, LayoutTokens.Spacing.md)
        .background(Theme.secondary.opacity(0.1))
        .clipShape(Capsule())

        Button(action: onEdit) {
          Text("Edit Profile")
            .font(.system(size: LayoutTokens.Typography.footnote, weight: .semibold))
            .foregroundStyle(Theme.secondary)
        }
        .buttonStyle(.plain)
        .padding(.top, LayoutTokens.Spacing.xs)
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
              .font(.system(size: LayoutTokens.Typography.avatar, weight: .bold, design: .rounded))
              .foregroundStyle(.white)
          )
      }
      .shadow(color: Theme.secondary.opacity(0.3), radius: 16, x: 0, y: 8)
    }
    .frame(maxWidth: .infinity)
    .padding(LayoutTokens.Padding.cardHero(for: sizeClass))
    .glassEffect(.regular)
  }
}
