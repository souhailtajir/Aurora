//
//  JournalInsightCard.swift
//  Aurora
//
//  Astrology-themed insight card for journal stats
//

import SwiftUI

struct JournalInsightCard: View {
  let totalEntries: Int
  let entriesThisMonth: Int

  @State private var animateStars = false
  @Environment(\.horizontalSizeClass) private var sizeClass

  private let accentGold = Color(red: 0.95, green: 0.82, blue: 0.55)

  var body: some View {
    HStack(spacing: 0) {
      // Left side - Stats
      VStack(alignment: .leading, spacing: LayoutTokens.Spacing.md) {
        // Title with subtle icon
        HStack(spacing: LayoutTokens.Spacing.sm) {
          Text("Your Journey")
            .font(.system(size: LayoutTokens.Typography.footnote, weight: .semibold))
            .foregroundStyle(accentGold.opacity(0.6))
            .textCase(.uppercase)
            .tracking(0.5)
        }

        // Main stat
        HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.Spacing.xs) {
          Text("\(totalEntries)")
            .font(.system(size: LayoutTokens.Typography.heroStat, weight: .bold, design: .rounded))
            .foregroundStyle(accentGold)

          Text(totalEntries == 1 ? "entry" : "entries")
            .font(.system(size: LayoutTokens.Typography.title3, weight: .medium))
            .foregroundStyle(accentGold.opacity(0.5))
        }
      }

      Spacer(minLength: 16)

      // Right side - Decorative celestial element
      ZStack {
        // Glowing orb background
        Circle()
          .fill(
            RadialGradient(
              colors: [
                accentGold.opacity(0.3),
                accentGold.opacity(0.1),
                .clear,
              ],
              center: .center,
              startRadius: 0,
              endRadius: 50
            )
          )
          .frame(width: 100, height: 100)

        // Center moon icon
        Image(systemName: "moon.stars.fill")
          .font(.system(size: 45, weight: .light))
          .foregroundStyle(
            LinearGradient(
              colors: [accentGold, accentGold.opacity(0.7)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .shadow(color: accentGold.opacity(0.3), radius: 8, x: 0, y: 2)
      }
      .frame(width: 100, height: 100)
    }
    .padding(LayoutTokens.Padding.cardInner(for: sizeClass))
    .padding(.horizontal, LayoutTokens.Spacing.lg)
    .frame(maxWidth: .infinity, alignment: .leading)
    .glassEffect(.clear.tint(Theme.secondary), in: .capsule)
    .onAppear {
      withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
        animateStars = true
      }
    }
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()
    VStack(spacing: 20) {
      JournalInsightCard(totalEntries: 47, entriesThisMonth: 12)
      JournalInsightCard(totalEntries: 1, entriesThisMonth: 1)
      JournalInsightCard(totalEntries: 0, entriesThisMonth: 0)
    }
    .padding()
  }
}
