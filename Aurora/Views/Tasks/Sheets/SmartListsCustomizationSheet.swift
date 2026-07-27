//
//  SmartListsCustomizationSheet.swift
//  Aurora
//
//  Created by souhail on 12/29/25.
//

import SwiftUI

struct SmartListsCustomizationSheet: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss

  @State private var visibleSmartLists: Set<SmartListType> = []
  @State private var smartListOrder: [SmartListType] = []

  var body: some View {
    NavigationStack {
      List {
        ForEach(smartListOrder, id: \.self) { listType in
          Toggle(
            isOn: Binding(
              get: { visibleSmartLists.contains(listType) },
              set: { isOn in
                if isOn {
                  visibleSmartLists.insert(listType)
                } else {
                  visibleSmartLists.remove(listType)
                }
              }
            )
          ) {
            HStack(spacing: 12) {
              SmartListIcon(listType: listType)
              Text(listType.rawValue)
            }
          }
          .tint(listType.tintColor)
        }
        .onMove { from, to in
          smartListOrder.move(fromOffsets: from, toOffset: to)
        }
      }
      .navigationTitle("Smart Lists")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          EditButton()
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            taskStore.visibleSmartLists = visibleSmartLists
            taskStore.smartListOrder = smartListOrder
            dismiss()
          }
          .fontWeight(.semibold)
        }
      }
      .onAppear {
        visibleSmartLists = taskStore.visibleSmartLists
        smartListOrder =
          taskStore.smartListOrder.isEmpty
          ? Array(SmartListType.allCases)
          : taskStore.smartListOrder
      }
    }
  }
}

struct SmartListIcon: View {
  let listType: SmartListType

  private var currentDay: Int {
    Calendar.current.component(.day, from: Date())
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 6)
        .fill(listType.tintColor)
        .frame(width: 28, height: 28)

      if listType == .today {
        Text("\(currentDay)")
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(.white)
      } else {
        Image(systemName: listType.icon)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.white)
      }
    }
  }
}

#Preview {
  PreviewContainer {
    SmartListsCustomizationSheet()
  }
}

