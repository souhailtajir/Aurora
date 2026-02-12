//
//  BirthDatePickerView.swift
//  Aurora
//  Created by souhail on 12/18/25.


import SwiftUI

struct BirthDatePickerView: View {
  let userProfileStore: UserProfileStore
  @Binding var isPresented: Bool
  @State private var selectedDate: Date

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

        VStack(spacing: 20) {
          // Preview Card
          VStack(spacing: 6) {
            Text(computedZodiac.symbol)
              .font(.system(size: 64))
              .padding(.bottom, 6)

            Text(computedZodiac.rawValue)
              .font(.system(size: 26, weight: .bold))
              .foregroundStyle(Theme.secondary)

            Text("Ruled by \(computedZodiac.rulingPlanet.displayName)")
              .font(.system(size: 16, weight: .medium))
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 32)
          .glassEffect(.clear)
          .padding(.horizontal, 20)

          // Date Picker Card
          VStack(spacing: 16) {
            Text("When were you born?")
              .font(.system(size: 17, weight: .semibold))
              .foregroundStyle(.primary)
              .frame(maxWidth: .infinity, alignment: .leading)

            DatePicker(
              "Birth Date",
              selection: $selectedDate,
              displayedComponents: [.date]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 140)
          }
          .padding(24)
          .glassEffect(.regular)
          .padding(.horizontal, 20)

          Spacer()
        }
        .padding(.top, 20)
      }
      .navigationTitle("Birth Date")
      .navigationBarTitleDisplayMode(.inline)
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
