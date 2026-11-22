import SwiftUI

struct BottomSearchBar: View {
  @Binding var text: String
  @Binding var isSearching: Bool
  var placeholder: String = "Search"
  @FocusState private var isFocused: Bool
  @Environment(\.horizontalSizeClass) private var sizeClass

  // Aurora purple accent color
  private let purpleAccent = Color(red: 0.6, green: 0.4, blue: 0.9)

  var body: some View {
    GlassEffectContainer {
      HStack(spacing: LayoutTokens.Spacing.md) {
        // Search field in glass capsule
        HStack(spacing: LayoutTokens.Spacing.sm) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: LayoutTokens.IconSize.md, weight: .medium))
            .foregroundStyle(Theme.primary)

          TextField(placeholder, text: $text)
            .font(.system(size: LayoutTokens.Typography.body + 1))
            .textFieldStyle(.plain)
            .focused($isFocused)
            .submitLabel(.search)
            .tint(purpleAccent)

          Spacer()

          // Mic icon on the right side of the field
          Image(systemName: "mic.fill")
            .font(.system(size: LayoutTokens.Typography.body))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, LayoutTokens.Spacing.md)
        .padding(.vertical, LayoutTokens.Spacing.sm + 4)
        .glassEffect(.clear.interactive())
        .clipShape(Capsule())

        // Circular X dismiss button (separate from search field)
        Button(action: dismissSearch) {
          Image(systemName: "xmark")
            .font(.system(size: LayoutTokens.IconSize.md))
            .foregroundStyle(Theme.primary)
        }
        .buttonStyle(.plain)
        .frame(width: LayoutTokens.IconSize.rowFrame, height: LayoutTokens.IconSize.rowFrame)
        .contentShape(Circle())
        .glassEffect(.clear.interactive())
        .clipShape(Circle())
      }
      .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
      .padding(.vertical, LayoutTokens.Spacing.sm + 4)
      .onAppear {
        if isSearching { isFocused = true }
      }
      .onChange(of: isSearching) { _, newValue in
        if newValue { isFocused = true }
      }
      .onChange(of: isFocused) { _, newValue in
        if newValue {
          withAnimation { isSearching = true }
        }
      }
    }
  }

  private func dismissSearch() {
    dismissKeyboard()

    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
      text = ""
      isSearching = false
      isFocused = false
    }
  }
}

#Preview {
  ZStack(alignment: .bottom) {
    Color.black.ignoresSafeArea()
    BottomSearchBar(text: .constant(""), isSearching: .constant(true))
  }
}
