//
//  CategoryCard.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import SwiftUI

struct CategoryCard: View {
  let icon: String
  let title: String
  let count: Int
  let color: Color
  @Environment(\.horizontalSizeClass) private var sizeClass

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        // Icon with subtle background
        Image(systemName: icon)
          .font(.system(size: LayoutTokens.IconSize.lg, weight: .bold))
          .foregroundStyle(color)

        Spacer()

        Text("\(count)")
          .font(.system(size: LayoutTokens.Typography.title1, weight: .bold))
          .foregroundStyle(color)
      }

      Spacer()

      Text(title)
        .font(.system(size: LayoutTokens.Typography.body, weight: .semibold))
        .foregroundStyle(color)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .padding(LayoutTokens.Padding.cardInner(for: sizeClass))
    .frame(height: LayoutTokens.CardHeight.category)  // Slightly taller for better proportions
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.clear)
    .glassEffect(.clear)  // User requested clear glass
    .clipShape(RoundedRectangle(cornerRadius: LayoutTokens.Radius.xl))
  }
}
