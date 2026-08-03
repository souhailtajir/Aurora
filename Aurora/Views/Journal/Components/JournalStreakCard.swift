//
//  JournalStreakCard.swift
//  Aurora
//
//  Wider streak card for journal writing streaks
//

import SwiftUI

struct JournalStreakCard: View {
  let streak: Int
  @Environment(\.horizontalSizeClass) private var sizeClass

  var body: some View {
    HStack(spacing: LayoutTokens.Spacing.lg) {
      // Flame icon
      ZStack {
        Circle()
          .fill(.orange.opacity(0.2))
          .frame(width: LayoutTokens.IconSize.circleBackground, height: LayoutTokens.IconSize.circleBackground)

        Image(systemName: "flame.fill")
          .font(.system(size: LayoutTokens.IconSize.xl, weight: .medium))
          .foregroundStyle(.orange)
      }

      // Text content
      VStack(alignment: .leading, spacing: LayoutTokens.Spacing.xs) {
        Text("Writing Streak")
          .font(.system(size: LayoutTokens.Typography.subheadline, weight: .medium))
          .foregroundStyle(.secondary)

        HStack(alignment: .firstTextBaseline, spacing: LayoutTokens.Spacing.xs) {
          Text("\(streak)")
            .font(.system(size: LayoutTokens.Typography.largeNumber, weight: .bold))
            .foregroundStyle(.orange)

          Text(streak == 1 ? "day" : "days")
            .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      // Streak indicator dots
      HStack(spacing: LayoutTokens.Spacing.xs) {
        ForEach(0..<min(streak, 7), id: \.self) { index in
          Circle()
            .fill(.orange.opacity(0.3 + Double(index) * 0.1))
            .frame(width: 6, height: 6)
        }
      }
    }
    .padding(LayoutTokens.Padding.cardInner(for: sizeClass))
    .frame(maxWidth: .infinity)
    .glassEffect(.regular.tint(.orange.opacity(0.15)))
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()
    VStack(spacing: 16) {
      JournalStreakCard(streak: 5)
      JournalStreakCard(streak: 1)
      JournalStreakCard(streak: 12)
    }
    .padding()
  }
}
