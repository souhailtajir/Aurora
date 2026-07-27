//
//  JournalSuggestionsSheet.swift
//  Aurora
//

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
          // Suggestions For You section
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

      ForEach(suggestedPrompts, id: \.title) { suggestion in
        Button {
          HapticService.shared.impact(.light)
          onSuggestionSelected(suggestion.prompt)
          dismiss()
        } label: {
          HStack(spacing: 12) {
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

  // MARK: - Suggested Prompts

  private var suggestedPrompts: [(icon: String, title: String, prompt: String)] {
    let calendar = Calendar.current
    let hour = calendar.component(.hour, from: Date())

    // Return contextual suggestions based on time of day
    if hour < 12 {
      return [
        ("sunrise.fill", "Start Your Day", "What are your intentions for today?"),
        ("cup.and.saucer.fill", "Morning Energy", "How did you sleep and how are you feeling right now?"),
      ]
    } else if hour < 17 {
      return [
        ("sun.max.fill", "Midday Check-in", "How is your day going so far?"),
        ("bolt.fill", "Momentum", "What have you accomplished today that you're proud of?"),
      ]
    } else {
      return [
        ("sunset.fill", "Wind Down", "What was the highlight of your day?"),
        ("moon.fill", "Evening Gratitude", "What are you thankful for today?"),
      ]
    }
  }
}

#Preview {
  JournalSuggestionsSheet { prompt in
    print("Selected: \(prompt)")
  }
  .preferredColorScheme(.dark)
}
