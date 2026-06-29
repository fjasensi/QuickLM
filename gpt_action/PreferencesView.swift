import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("LM Studio") {
                TextField("Base URL", text: $settings.baseURL)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 8) {
                    Text("System Prompt")
                        .font(.headline)
                    TextEditor(text: $settings.systemPrompt)
                        .font(.body)
                        .frame(minHeight: 96)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color(nsColor: .separatorColor))
                        )
                }

                HStack {
                    Text("Temperature")
                        .frame(width: 110, alignment: .leading)
                    Slider(value: $settings.temperature, in: 0...2, step: 0.1)
                    Text(settings.temperature.formatted(.number.precision(.fractionLength(1))))
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }

                HStack {
                    Text("Response Timeout")
                        .frame(width: 130, alignment: .leading)
                    Slider(value: $settings.responseTimeout, in: 30...600, step: 15)
                    Text(timeoutLabel)
                        .monospacedDigit()
                        .frame(width: 56, alignment: .trailing)
                }
            }

            Section("Keyboard") {
                Picker("Global Hotkey", selection: $settings.selectedHotkeyID) {
                    ForEach(HotkeyShortcut.presets) { shortcut in
                        Text(shortcut.displayName).tag(shortcut.id)
                    }
                }
                .pickerStyle(.menu)
            }

            HStack {
                Spacer()
                Button {
                    settings.resetDefaults()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 560, height: 470)
    }

    private var timeoutLabel: String {
        let seconds = Int(settings.responseTimeout)

        if seconds >= 60, seconds % 60 == 0 {
            return "\(seconds / 60)m"
        }

        return "\(seconds)s"
    }
}
