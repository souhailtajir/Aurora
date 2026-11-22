//
//  CategoriesView.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import SwiftUI

struct CategoriesView: View {
    @Environment(TaskStore.self) var taskStore
    @Environment(\.dismiss) var dismiss
    @State private var showingAddCategory = false
    @State private var categoryToEdit: TaskCategory?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(taskStore.categories) { category in
                    Button(action: {
                        categoryToEdit = category
                    }) {
                        HStack {
                            Circle()
                                .fill(Color(hex: category.colorHex))
                                .frame(width: 12, height: 12)
                            
                            Image(systemName: category.iconName)
                                .foregroundStyle(Theme.secondary)
                            
                            Text(category.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Theme.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary.opacity(0.5))
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        taskStore.deleteCategory(taskStore.categories[index])
                    }
                }
            }
            .navigationTitle("Categories")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .platformTopBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .platformTopBarTrailing) {
                    Button(action: {
                        showingAddCategory = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                CategoryEditView()
            }
            .sheet(item: $categoryToEdit) { category in
                CategoryEditView(category: category)
            }
        }
    }
}

struct CategoryEditView: View {
    @Environment(TaskStore.self) var taskStore
    @Environment(\.dismiss) var dismiss
    
    var category: TaskCategory?
    
    @State private var name: String = ""
    @State private var color: Color = .blue
    @State private var icon: String = "tag.fill"
    
    let icons = ["tag.fill", "briefcase.fill", "cart.fill", "heart.fill", "star.fill", "flag.fill", "book.fill", "gamecontroller.fill", "tv.fill", "music.note"]
    
    init(category: TaskCategory? = nil) {
        self.category = category
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Category Name", text: $name)
                    ColorPicker("Color", selection: $color)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(icons, id: \.self) { iconName in
                            Image(systemName: iconName)
                                .font(.system(size: 24))
                                .foregroundStyle(icon == iconName ? Theme.primary : .secondary)
                                .frame(width: 44, height: 44)
                                .background(icon == iconName ? Theme.primary.opacity(0.1) : Color.clear)
                                .clipShape(Circle())
                                .onTapGesture {
                                    icon = iconName
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(category == nil ? "New Category" : "Edit Category")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let category = category {
                    name = category.name
                    color = Color(hex: category.colorHex)
                    icon = category.iconName
                }
            }
        }
    }
    
    private func save() {
        let hex = color.toHex() ?? "#000000"
        
        if let category = category {
            category.name = name
            category.colorHex = hex
            category.iconName = icon
            taskStore.updateCategory(category)
        } else {
            let newCategory = TaskCategory(name: name, colorHex: hex, iconName: icon)
            taskStore.addCategory(newCategory)
        }
        dismiss()
    }
}

extension Color {
    func toHex() -> String? {
        platformHex()
    }
}

#Preview {
    CategoriesView()
}
