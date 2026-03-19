//  EntryEditorView.swift
//  Aurora
//

import AVFoundation
import CoreLocation
import PhotosUI
import SwiftUI

struct EntryEditorView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss
  let entryId: UUID

  @State private var title = ""
  @State private var entryBody = ""
  @State private var hasLoaded = false
  @State private var selectedPhoto: PhotosPickerItem?
  @FocusState private var titleFocused: Bool
  @FocusState private var bodyFocused: Bool

  // Toolbar state
  @State private var showCamera = false
  @State private var showSuggestions = false
  @State private var showVoiceAlert = false
  @State private var showMagicAlert = false
  @State private var locationService = LocationService()
  @State private var isLoadingLocation = false

  private var entry: JournalEntry? {
    taskStore.journalEntries.first { $0.id == entryId }
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      if entry != nil {
        editorContent
      } else {
        emptyState
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.clear.auroraBackground())
    .navigationTitle(title.isEmpty ? "New Entry" : title)
    .toolbarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 16, weight: .semibold))
        }
      }

      ToolbarItem(placement: .topBarTrailing) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "checkmark")
            .font(.system(size: 16, weight: .bold))
        }
        .buttonStyle(.glassProminent)
        .tint(Theme.primary)
      }
    }
    .safeAreaInset(edge: .bottom) {
      bottomToolbar
    }
    .onAppear {
      loadEntry()
    }
    .fullScreenCover(isPresented: $showCamera) {
      CameraPicker { imageData in
        addImageToEntry(imageData)
      }
      .ignoresSafeArea()
    }
    .sheet(isPresented: $showSuggestions) {
      JournalSuggestionsSheet { prompt in
        if entryBody.isEmpty {
          entryBody = prompt
        } else {
          entryBody += "\n\n" + prompt
        }
        save()
      }
    }
    .alert("Voice Recording", isPresented: $showVoiceAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(
        "Voice recording feature coming soon! This will allow you to add audio notes to your journal entries."
      )
    }
    .alert("Writing Tools", isPresented: $showMagicAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(
        "AI writing assistance feature coming soon! This will help enhance and polish your journal entries."
      )
    }
  }

  // MARK: - Bottom Toolbar

  private var bottomToolbar: some View {
    HStack(spacing: 28) {
      // Journaling suggestions
      Button {
        showSuggestions = true
      } label: {
        Image(systemName: "sparkles")
          .font(.system(size: 22))
          .foregroundStyle(Theme.tint)
      }

      // Photo library picker
      PhotosPicker(selection: $selectedPhoto, matching: .images) {
        Image(systemName: "photo.on.rectangle")
          .font(.system(size: 22))
          .foregroundStyle(Theme.tint)
      }
      .onChange(of: selectedPhoto) { _, newItem in
        if let item = newItem {
          loadPhoto(item)
        }
      }

      // Camera
      Button {
        requestCameraAccess()
      } label: {
        Image(systemName: "camera")
          .font(.system(size: 22))
          .foregroundStyle(Theme.tint)
      }

      // Voice recording
      Button {
        showVoiceAlert = true
      } label: {
        Image(systemName: "waveform")
          .font(.system(size: 22))
          .foregroundStyle(Theme.tint)
      }

      // Location - toggle on/off
      Button {
        toggleLocation()
      } label: {
        if isLoadingLocation {
          ProgressView()
            .tint(Theme.tint)
        } else {
          Image(systemName: entry?.locationName != nil ? "location.fill" : "location")
            .font(.system(size: 22))
            .foregroundStyle(entry?.locationName != nil ? Theme.primary : Theme.tint)
        }
      }

      // Magic wand / writing tools
      Button {
        showMagicAlert = true
      } label: {
        Image(systemName: "wand.and.stars")
          .font(.system(size: 22))
          .foregroundStyle(Theme.tint)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
    .background {
      Capsule()
        .glassEffect(.regular)
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 8)
  }

  // MARK: - Editor Content

  private var editorContent: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 12) {
        // Title field
        TextField("Title", text: $title)
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(.primary)
          .focused($titleFocused)
          .submitLabel(.next)
          .onSubmit { bodyFocused = true }
          .onChange(of: title) { _, _ in save() }

        Divider()
          .background(.secondary.opacity(0.3))

        // Location badge
        if let locationName = entry?.locationName {
          HStack(spacing: 6) {
            Image(systemName: "location.fill")
              .font(.system(size: 12))
            Text(locationName)
              .font(.system(size: 13))
          }
          .foregroundStyle(Theme.primary)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background {
            Capsule()
              .fill(Theme.primary.opacity(0.15))
          }
        }

        // Body editor
        ZStack(alignment: .topLeading) {
          if entryBody.isEmpty {
            Text("Start writing...")
              .font(.system(size: 17))
              .foregroundStyle(.secondary.opacity(0.5))
              .padding(.top, 8)
          }

          TextEditor(text: $entryBody)
            .font(.system(size: 17))
            .foregroundStyle(.primary)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 300)
            .focused($bodyFocused)
            .onChange(of: entryBody) { _, _ in save() }
        }

        // Images
        if let entry = entry, !entry.images.isEmpty {
          imagesGrid(entry.images)
        }

        Spacer(minLength: 100)
      }
      .padding(.horizontal, 20)
      .padding(.top, 16)
    }
  }

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: 16) {
      Image(systemName: "doc.questionmark")
        .font(.system(size: 40))
        .foregroundStyle(.secondary)
      Text("Entry not found")
        .font(.system(size: 16))
        .foregroundStyle(.secondary)
    }
  }

  // MARK: - Images Grid

  private func imagesGrid(_ images: [Data]) -> some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
      ForEach(Array(images.enumerated()), id: \.offset) { index, data in
        if let uiImage = UIImage(data: data) {
          ZStack(alignment: .topTrailing) {
            Image(uiImage: uiImage)
              .resizable()
              .scaledToFill()
              .frame(width: 80, height: 80)
              .clipShape(RoundedRectangle(cornerRadius: 10))

            Button {
              removeImage(at: index)
            } label: {
              Image(systemName: "xmark.circle.fill")
                .font(.system(size: 18))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .black.opacity(0.5))
            }
            .offset(x: 4, y: -4)
          }
        }
      }
    }
  }

  // MARK: - Actions

  private func loadEntry() {
    guard !hasLoaded, let entry = entry else { return }
    title = entry.title
    entryBody = entry.body
    hasLoaded = true

    if entry.title.isEmpty && entry.body.isEmpty {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        titleFocused = true
      }
    }
  }

  private func save() {
    guard hasLoaded, let entry = entry else { return }
    entry.title = title
    entry.body = entryBody
    taskStore.updateJournalEntry(entry)
  }

  private func loadPhoto(_ item: PhotosPickerItem) {
    AsyncTask {
      if let data = try? await item.loadTransferable(type: Data.self) {
        addImageToEntry(data)
        selectedPhoto = nil
      }
    }
  }

  private func addImageToEntry(_ data: Data) {
    guard let entry = entry else { return }
    entry.images.append(data)
    taskStore.updateJournalEntry(entry)
  }

  private func removeImage(at index: Int) {
    guard let entry = entry else { return }
    entry.images.remove(at: index)
    taskStore.updateJournalEntry(entry)
  }

  private func requestCameraAccess() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      showCamera = true
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        if granted {
          AsyncTask { @MainActor in
            showCamera = true
          }
        }
      }
    default:
      break
    }
  }

  private func toggleLocation() {
    // If location already exists, remove it
    if entry?.locationName != nil {
      guard let entry = entry else { return }
      entry.locationName = nil
      entry.latitude = nil
      entry.longitude = nil
      taskStore.updateJournalEntry(entry)
      return
    }

    // Otherwise, add location
    AsyncTask {
      isLoadingLocation = true

      if let location = await locationService.getCurrentLocation() {
        guard let entry = entry else {
          isLoadingLocation = false
          return
        }

        entry.latitude = location.coordinate.latitude
        entry.longitude = location.coordinate.longitude

        if let name = await locationService.reverseGeocode(location) {
          entry.locationName = name
        }

        taskStore.updateJournalEntry(entry)
      }

      isLoadingLocation = false
    }
  }
}
