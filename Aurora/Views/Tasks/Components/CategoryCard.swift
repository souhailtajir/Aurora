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

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        // Icon with subtle background
        Image(systemName: icon)
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(color)

        Spacer()

        Text("\(count)")
          .font(.system(size: 24, weight: .bold))
          .foregroundStyle(color)
      }

      Spacer()

      Text(title)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(color)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .padding(20)
    .frame(height: 110)  // Slightly taller for better proportions
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.clear)
    .glassEffect(.clear)  // User requested clear glass
    .clipShape(RoundedRectangle(cornerRadius: 24))
  }
}

#Preview {
  HStack(spacing: 12) {
    CategoryCard(icon: "briefcase.fill", title: "Work", count: 5, color: Color(hex: "66B3FF"))
    CategoryCard(icon: "person.fill", title: "Personal", count: 3, color: Color(hex: "B366F3"))
  }
  .padding()
  .preferredColorScheme(.dark)
}
