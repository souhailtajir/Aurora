//  EntryEditorView.swift
//  Aurora
//

import AVFoundation
import CoreLocation
import PhotosUI
import Speech
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
  @Environment(\.horizontalSizeClass) private var sizeClass

  // Toolbar state
  @State private var showCamera = false
  @State private var showMagicAlert = false
  @State private var locationService = LocationService()
  @State private var isLoadingLocation = false

  // Dictation state
  @State private var isDictating = false
  @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
  @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  @State private var recognitionTask: SFSpeechRecognitionTask?
  @State private var audioEngine = AVAudioEngine()

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
            .font(.system(size: LayoutTokens.Typography.body, weight: .semibold))
        }
      }

      ToolbarItem(placement: .topBarTrailing) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "checkmark")
            .font(.system(size: LayoutTokens.Typography.body, weight: .bold))
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
    HStack(spacing: LayoutTokens.Spacing.xl) {
      // Photo library picker
      PhotosPicker(selection: $selectedPhoto, matching: .images) {
        Image(systemName: "photo.on.rectangle")
          .font(.system(size: LayoutTokens.IconSize.lg))
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
          .font(.system(size: LayoutTokens.IconSize.lg))
          .foregroundStyle(Theme.tint)
      }

      // Voice dictation
      Button {
        toggleDictation()
      } label: {
        Image(systemName: isDictating ? "mic.fill" : "waveform")
          .font(.system(size: LayoutTokens.IconSize.lg))
          .foregroundStyle(isDictating ? .red : Theme.tint)
          .symbolEffect(.pulse, isActive: isDictating)
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
            .font(.system(size: LayoutTokens.IconSize.lg))
            .foregroundStyle(entry?.locationName != nil ? Theme.primary : Theme.tint)
        }
      }

      // Magic wand / writing tools
      Button {
        showMagicAlert = true
      } label: {
        Image(systemName: "wand.and.stars")
          .font(.system(size: LayoutTokens.IconSize.lg))
          .foregroundStyle(Theme.tint)
      }
    }
    .padding(.horizontal, LayoutTokens.Spacing.xl)
    .padding(.vertical, LayoutTokens.Spacing.sm + 2)
    .background {
      Capsule()
        .glassEffect(.clear)
    }
    .padding(.horizontal, LayoutTokens.Spacing.xxl)
    .padding(.bottom, LayoutTokens.Spacing.sm)
  }

  // MARK: - Editor Content

  private var editorContent: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: LayoutTokens.Spacing.md) {
        // Title field
        TextField("Title", text: $title)
          .font(.system(size: LayoutTokens.Typography.title2, weight: .medium))
          .foregroundStyle(.primary)
          .focused($titleFocused)
          .submitLabel(.next)
          .onSubmit { bodyFocused = true }
          .onChange(of: title) { _, _ in save() }

        Divider()
          .background(.secondary.opacity(0.3))

        // Location badge
        if let locationName = entry?.locationName {
          HStack(spacing: LayoutTokens.Spacing.xs) {
            Image(systemName: "location.fill")
              .font(.system(size: LayoutTokens.Typography.caption))
            Text(locationName)
              .font(.system(size: LayoutTokens.Typography.footnote))
          }
          .foregroundStyle(Theme.primary)
          .padding(.horizontal, LayoutTokens.Spacing.sm + 2)
          .padding(.vertical, LayoutTokens.Spacing.xs + 2)
          .background {
            Capsule()
              .fill(Theme.primary.opacity(0.15))
          }
        }

        // Body editor
        ZStack(alignment: .topLeading) {
          if entryBody.isEmpty {
            Text("Start writing...")
              .font(.system(size: LayoutTokens.Typography.body + 1))
              .foregroundStyle(.secondary.opacity(0.5))
              .padding(.top, LayoutTokens.Spacing.sm)
          }

          TextEditor(text: $entryBody)
            .font(.system(size: LayoutTokens.Typography.body + 1))
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
      .padding(.horizontal, LayoutTokens.Padding.screenHorizontal(for: sizeClass))
      .padding(.top, LayoutTokens.Spacing.lg)
    }
  }

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: LayoutTokens.Spacing.lg) {
      Image(systemName: "doc.questionmark")
        .font(.system(size: LayoutTokens.Typography.emptyStateIcon + 4))
        .foregroundStyle(.secondary)
      Text("Entry not found")
        .font(.system(size: LayoutTokens.Typography.body))
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
                .font(.system(size: LayoutTokens.IconSize.md))
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

  // MARK: - Dictation

  private func toggleDictation() {
    if isDictating {
      stopDictation()
    } else {
      startDictation()
    }
  }

  private func startDictation() {
    SFSpeechRecognizer.requestAuthorization { status in
      guard status == .authorized else { return }

      AVAudioApplication.requestRecordPermission { granted in
        guard granted else { return }

        AsyncTask { @MainActor in
          do {
            try beginAudioRecognition()
            isDictating = true
            HapticService.shared.impact(.medium)
          } catch {
            print("Failed to start dictation: \(error)")
          }
        }
      }
    }
  }

  private func beginAudioRecognition() throws {
    // Cancel any existing task
    recognitionTask?.cancel()
    recognitionTask = nil

    let audioSession = AVAudioSession.sharedInstance()
    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    guard let recognitionRequest = recognitionRequest else { return }
    recognitionRequest.shouldReportPartialResults = true

    let textBeforeDictation = entryBody

    recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
      if let result = result {
        let transcription = result.bestTranscription.formattedString
        if textBeforeDictation.isEmpty {
          entryBody = transcription
        } else {
          entryBody = textBeforeDictation + "\n" + transcription
        }
      }

      if error != nil || (result?.isFinal ?? false) {
        stopDictation()
      }
    }

    let inputNode = audioEngine.inputNode
    let recordingFormat = inputNode.outputFormat(forBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
      recognitionRequest.append(buffer)
    }

    audioEngine.prepare()
    try audioEngine.start()
  }

  private func stopDictation() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionRequest?.endAudio()
    recognitionRequest = nil
    recognitionTask?.cancel()
    recognitionTask = nil
    isDictating = false
    save()
    HapticService.shared.impact(.light)

    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }
}
