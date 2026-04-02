import SwiftUI

struct BottomSearchBar: View {
  @Binding var text: String
  @Binding var isSearching: Bool
  var placeholder: String = "Search"
  @FocusState private var isFocused: Bool

  // Aurora purple accent color
  private let purpleAccent = Color(red: 0.6, green: 0.4, blue: 0.9)

  var body: some View {
    GlassEffectContainer {
      HStack(spacing: 12) {
        // Search field in glass capsule
        HStack(spacing: 10) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(Theme.primary)

          TextField(placeholder, text: $text)
            .font(.system(size: 17))
            .textFieldStyle(.plain)
            .focused($isFocused)
            .submitLabel(.search)
            .tint(purpleAccent)

          Spacer()

          // Mic icon on the right side of the field
          Image(systemName: "mic.fill")
            .font(.system(size: 16))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular.interactive())
        .clipShape(Capsule())

        // Circular X dismiss button (separate from search field)
        Button(action: dismissSearch) {
          Image(systemName: "xmark")
            .font(.system(size: 18))
            .foregroundStyle(Theme.primary)
        }
        .buttonStyle(.plain)
        .frame(width: 44, height: 44)
        .contentShape(Circle())
        .glassEffect(.regular.interactive())
        .clipShape(Circle())
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
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
    // Dismiss keyboard first
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
