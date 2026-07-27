//
//  CategoriesManagementSheet.swift
//  Aurora
//
//  Created by souhail on 12/30/25.
//

import SwiftUI

struct CategoriesManagementSheet: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss

  @State private var showingAddCategory = false
  @State private var editingCategory: TaskCategory? = nil

  var body: some View {
    NavigationStack {
      List {
        Section {
          ForEach(taskStore.categories) { category in
            HStack(spacing: 12) {
              ZStack {
                RoundedRectangle(cornerRadius: 6)
                  .fill(Color(hex: category.colorHex))
                  .frame(width: 28, height: 28)

                Image(systemName: category.iconName)
                  .font(.system(size: 12, weight: .semibold))
                  .foregroundStyle(.white)
              }

              Text(category.name)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
              Button(role: .destructive) {
                taskStore.deleteCategory(category)
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }
          .onMove { from, to in
            taskStore.categories.move(fromOffsets: from, toOffset: to)
          }
        } header: {
          Text("My Lists")
        }

        Section {
          Button {
            showingAddCategory = true
          } label: {
            Label("Add List", systemImage: "plus")
          }
        }
      }
      .navigationTitle("Edit Lists")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          EditButton()
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
          .fontWeight(.semibold)
        }
      }
      .sheet(isPresented: $showingAddCategory) {
        CategoryEditView()
          .presentationDetents([.medium])
      }
    }
  }
}

#Preview {
  PreviewContainer {
    CategoriesManagementSheet()
  }
}

