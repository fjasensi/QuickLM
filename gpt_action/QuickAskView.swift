import SwiftUI

struct QuickAskView: View {
    @ObservedObject var viewModel: QuickAskViewModel
    let onClose: () -> Void

    @FocusState private var isPromptFocused: Bool

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.tint)

                TextField("Ask QuickLM...", text: $viewModel.prompt)
                    .textFieldStyle(.plain)
                    .font(.system(size: 24, weight: .regular))
                    .focused($isPromptFocused)
                    .disabled(viewModel.isLoading)
                    .onSubmit {
                        viewModel.sendCurrentPrompt()
                    }

                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            responseArea

            HStack {
                if let activeModel = viewModel.activeModel {
                    Label(activeModel, systemImage: "cpu")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if viewModel.isCheckingModel {
                    Label("Checking model...", systemImage: "cpu")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Label("No model detected", systemImage: "cpu")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    viewModel.copyAnswer()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .disabled(viewModel.answer.isEmpty)

                Button {
                    viewModel.startNewChat()
                } label: {
                    Label("New Chat", systemImage: "plus.message")
                }
            }
            .buttonStyle(.borderless)
        }
        .padding(18)
        .frame(width: 720, height: 430)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.16))
        )
        .onAppear(perform: focusPromptSoon)
        .onChange(of: viewModel.focusToken) {
            focusPromptSoon()
        }
            .onExitCommand(perform: onClose)
    }

    @ViewBuilder
    private var responseArea: some View {
        ZStack(alignment: .topLeading) {
            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding(16)
            } else if viewModel.isLoading {
                Label("Thinking...", systemImage: "brain")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(16)
            } else if viewModel.answer.isEmpty {
                Text("Ready")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(16)
            } else {
                MarkdownResponseView(text: viewModel.answer)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.38), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func focusPromptSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            isPromptFocused = true
        }
    }
}
