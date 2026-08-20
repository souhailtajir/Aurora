//
//  BirthDatePickerView.swift
//  Aurora
//  Created by souhail on 12/18/25.


import SwiftUI

struct BirthDatePickerView: View {
  let userProfileStore: UserProfileStore
  @Binding var isPresented: Bool
  @State private var selectedDate: Date
  @Environment(\.horizontalSizeClass) private var sizeClass

  init(userProfileStore: UserProfileStore, isPresented: Binding<Bool>) {
    self.userProfileStore = userProfileStore
    self._isPresented = isPresented
    self._selectedDate = State(initialValue: userProfileStore.profile.birthDate ?? Date())
  }

  var computedZodiac: ZodiacSign {
    ZodiacSign.from(birthDate: selectedDate)
  }

  var body: some View {
    NavigationStack {
      ZStack {
        // Background gradient
        Theme.auroraBackground
          .ignoresSafeArea()

        VStack(spacing: LayoutTokens.Spacing.xl) {
          // Preview Card
          VStack(spacing: LayoutTokens.Spacing.sm) {
            Text(computedZodiac.symbol)
              .font(.system(size: 64))
              .padding(.bottom, 6)

            Text(computedZodiac.rawValue)
              .font(.system(size: LayoutTokens.Typography.largeNumber, weight: .bold))
              .foregroundStyle(Theme.secondary)

            Text("Ruled by \(computedZodiac.rulingPlanet.displayName)")
              .font(.system(size: LayoutTokens.Typography.body, weight: .medium))
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, LayoutTokens.Spacing.xxl)
          .glassEffect(.clear)
          .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))

          // Date Picker Card
          VStack(spacing: LayoutTokens.Spacing.lg) {
            Text("When were you born?")
              .font(.system(size: LayoutTokens.Typography.headline, weight: .semibold))
              .foregroundStyle(.primary)
              .frame(maxWidth: .infinity, alignment: .leading)

            #if os(iOS)
            DatePicker(
              "Birth Date",
              selection: $selectedDate,
              displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 140)
            #else
            DatePicker(
              "Birth Date",
              selection: $selectedDate,
              displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            #endif
          }
          .padding(LayoutTokens.Padding.cardHero(for: sizeClass))
          .glassEffect(.regular)
          .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))

          Spacer()
        }
        .padding(.top, LayoutTokens.Padding.sectionTop)
      }
      .navigationTitle("Birth Date")
      .toolbarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            isPresented = false
          }
          .foregroundStyle(.secondary)
        }

        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            userProfileStore.updateBirthDate(selectedDate)
            isPresented = false
          }
          .fontWeight(.bold)
          .foregroundStyle(Theme.secondary)
        }
      }
    }
  }
}

#Preview {
  BirthDatePickerView(
    userProfileStore: UserProfileStore(),
    isPresented: .constant(true)
  )
}
