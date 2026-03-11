//
//  SmartListCard.swift
//  Aurora
//
//  Created by souhail on 12/29/25.
//

import SwiftUI

struct SmartListCard: View {
  let listType: SmartListType
  let count: Int
  let action: () -> Void

  private var currentDay: Int {
    Calendar.current.component(.day, from: Date())
  }

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .top) {
          iconView
          Spacer()
          Text("\(count)")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(listType.tintColor)
        }

        Spacer()

        Text(listType.rawValue)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.primary)
          .lineLimit(1)
      }
      .padding(16)
      .frame(height: 90)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .glassEffect(.clear.tint(listType.tintColor.opacity(0.3)))
  }

  @ViewBuilder
  private var iconView: some View {
    if listType == .today {
      // Today icon shows current day number like Apple Reminders
      ZStack {
        Image(systemName: "calendar")
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(listType.tintColor)

        Text("\(currentDay)")
          .font(.system(size: 10, weight: .bold))
          .foregroundStyle(listType.tintColor)
          .offset(y: 3)
      }
    } else {
      Image(systemName: listType.icon)
        .font(.system(size: 22, weight: .medium))
        .foregroundStyle(listType.tintColor)
    }
  }
}

/// Card for displaying user-created categories
struct CategorySmartCard: View {
  let category: TaskCategory
  let count: Int
  let action: () -> Void

  private var categoryColor: Color {
    Color(hex: category.colorHex)
  }

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .top) {
          Image(systemName: category.iconName)
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(categoryColor)

          Spacer()

          Text("\(count)")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(categoryColor)
        }

        Spacer()

        Text(category.name)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.primary)
          .lineLimit(1)
      }
      .padding(16)
      .frame(height: 90)
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .glassEffect(.clear.tint(categoryColor.opacity(0.3)))
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()

    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
      SmartListCard(listType: .today, count: 5) {}
      SmartListCard(listType: .all, count: 12) {}
      SmartListCard(listType: .flagged, count: 3) {}
      CategorySmartCard(category: .work, count: 8) {}
    }
    .padding()
  }
}
