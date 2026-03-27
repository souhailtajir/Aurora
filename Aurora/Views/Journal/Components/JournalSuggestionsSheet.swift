//
//  JournalSuggestionsSheet.swift
//  Aurora
//

import JournalingSuggestions
import SwiftUI

struct JournalSuggestionsSheet: View {
  @Environment(\.dismiss) private var dismiss
  var onSuggestionSelected: (String) -> Void

  private let staticPrompts: [(icon: String, title: String, prompt: String)] = [
    ("sun.horizon", "Morning Reflection", "How are you feeling this morning?"),
    ("heart.fill", "Gratitude", "List three things you're grateful for today."),
    ("brain.head.profile", "Mindfulness", "What thoughts are on your mind right now?"),
    ("star.fill", "Highlight", "What was the best moment of your day?"),
    ("moon.stars.fill", "Evening Reflection", "What went well today?"),
    ("lightbulb.fill", "Creative Spark", "Write about a recent idea or inspiration."),
  ]

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Text("Writing Prompts")
          .font(.system(size: 18, weight: .semibold))
        Spacer()
        Button("Done") {
          dismiss()
        }
        .foregroundStyle(Theme.primary)
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .padding(.bottom, 16)

      ScrollView(showsIndicators: false) {
        VStack(spacing: 16) {
          // Apple Journaling Suggestions Picker
          journalingSuggestionsSection

          // Static prompts
          staticPromptsSection
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(24)
  }

  // MARK: - Journaling Suggestions Section

  private var journalingSuggestionsSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label("Suggestions For You", systemImage: "sparkles")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      JournalingSuggestionsPicker {
        HStack(spacing: 12) {
          Image(systemName: "wand.and.stars")
            .font(.system(size: 20))
            .foregroundStyle(Theme.primary)
            .frame(width: 32)

          Text("Browse Suggestions")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.primary)

          Spacer()

          Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
          RoundedRectangle(cornerRadius: 12)
            .glassEffect(.clear)
        }
      } onCompletion: { suggestion in
        handleSuggestion(suggestion)
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - Static Prompts Section

  private var staticPromptsSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label("Writing Prompts", systemImage: "text.quote")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      ForEach(staticPrompts, id: \.title) { suggestion in
        Button {
          HapticService.shared.impact(.light)
          onSuggestionSelected(suggestion.prompt)
          dismiss()
        } label: {
          HStack(spacing: 14) {
            Image(systemName: suggestion.icon)
              .font(.system(size: 20))
              .foregroundStyle(Theme.primary)
              .frame(width: 32)

            Text(suggestion.title)
              .font(.system(size: 15, weight: .medium))
              .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "plus")
              .font(.system(size: 18))
              .foregroundStyle(Theme.primary.opacity(0.6))
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 12)
          .background {
            RoundedRectangle(cornerRadius: 12)
              .glassEffect(.clear)
          }
        }
        .buttonStyle(.plain)
      }
    }
  }

  // MARK: - Handle Apple Suggestion

  private func handleSuggestion(_ suggestion: JournalingSuggestion) {
    HapticService.shared.notification(.success)

    var parts: [String] = []

    if !suggestion.title.isEmpty {
      parts.append("## \(suggestion.title)")
    }

    let text = parts.joined(separator: "\n\n")
    onSuggestionSelected(text.isEmpty ? suggestion.title : text)
    dismiss()
  }
}
