//
//  SuggestedListRow.swift
//  Aurora
//
//  Created by souhail on 12/29/25.
//

import SwiftUI

struct SuggestedListRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  let subtitle: String
  let onAdd: () -> Void
  @Environment(\.horizontalSizeClass) private var sizeClass

  var body: some View {
    HStack(spacing: LayoutTokens.Spacing.md) {
      // Icon with colored background
      ZStack {
        Circle()
          .fill(iconColor)
          .frame(width: LayoutTokens.CardHeight.suggestedIcon, height: LayoutTokens.CardHeight.suggestedIcon)

        Image(systemName: icon)
          .font(.system(size: LayoutTokens.Typography.body, weight: .semibold))
          .foregroundStyle(.white)
      }

      // Title and subtitle
      VStack(alignment: .leading, spacing: LayoutTokens.Spacing.xs) {
        Text(title)
          .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
          .foregroundStyle(.primary)

        Text(subtitle)
          .font(.system(size: LayoutTokens.Typography.footnote))
          .foregroundStyle(.secondary)
      }

      Spacer()

      // Add button
      Button(action: onAdd) {
        Image(systemName: "plus.circle.fill")
          .font(.system(size: LayoutTokens.IconSize.xl))
          .foregroundStyle(.blue)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
    .padding(.vertical, LayoutTokens.Spacing.md)
    .background(Color.clear)
    .glassEffect(.clear)
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()

    VStack {
      SuggestedListRow(
        icon: "syringe.fill",
        iconColor: .green,
        title: "Suggested List: Groceries",
        subtitle: "Automatically categorizes items"
      ) {
        print("Add tapped")
      }
    }
    .padding()
  }
}
