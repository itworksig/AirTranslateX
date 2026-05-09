import SwiftUI

struct SidebarView: View {
    @Bindable var session: TranslationSessionStore

    var body: some View {
        Form {
            Section(AppText.capture) {
                Button {
                    session.isRunning ? session.stop() : session.start()
                } label: {
                    Label(session.isRunning ? AppText.stop : AppText.start, systemImage: session.isRunning ? "stop.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)

                Text(session.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if session.statusMessage.localizedCaseInsensitiveContains("permission")
                    || session.statusMessage.localizedCaseInsensitiveContains("권한") {
                    Button {
                        session.openPrivacySettings()
                    } label: {
                        Label(AppText.openPrivacySettings, systemImage: "gear")
                    }
                }
            }

            Section(AppText.languages) {
                Picker(AppText.from, selection: $session.sourceLanguage) {
                    ForEach(LanguageOption.supported) { language in
                        Text(language.localizedTitle).tag(language)
                    }
                }

                Picker(AppText.to, selection: $session.targetLanguage) {
                    ForEach(LanguageOption.supported) { language in
                        Text(language.localizedTitle).tag(language)
                    }
                }
            }

            Section(AppText.model) {
                Picker(AppText.model, selection: $session.selectedModel) {
                    ForEach(IntelligenceModel.allCases) { model in
                        Text(model.title).tag(model)
                    }
                }

                Text(session.selectedModel.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(AppText.output) {
                Toggle(AppText.dubbing, isOn: $session.isDubbingEnabled)
            }

            Section(AppText.savedTranscripts) {
                Button {
                    session.saveCurrentTranscript()
                } label: {
                    Label(AppText.saveCurrent, systemImage: "tray.and.arrow.down")
                }
                .disabled(!session.canSaveCurrentTranscript)

                if session.savedTranscripts.isEmpty {
                    Text(AppText.savedEmpty)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(session.savedTranscripts) { transcript in
                        Button {
                            session.selectSavedTranscript(transcript.id)
                        } label: {
                            SavedTranscriptRow(
                                transcript: transcript,
                                isSelected: session.selectedSavedTranscriptID == transcript.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if session.selectedSavedTranscriptID != nil {
                Section(AppText.editSaved) {
                    TextField(AppText.title, text: $session.savedDraftTitle)

                    Text(AppText.original)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $session.savedDraftSourceText)
                        .font(.caption)
                        .frame(minHeight: 90)

                    Text(AppText.translation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $session.savedDraftTranslatedText)
                        .font(.caption)
                        .frame(minHeight: 90)

                    HStack {
                        Button {
                            session.saveSelectedTranscriptEdits()
                        } label: {
                            Label(AppText.saveEdits, systemImage: "checkmark")
                        }

                        Button(role: .destructive) {
                            session.deleteSelectedTranscript()
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("AirTranslate")
    }
}

private struct SavedTranscriptRow: View {
    let transcript: SavedTranscript
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: isSelected ? "doc.text.fill" : "doc.text")
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(transcript.title)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                Text(transcript.updatedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}
