import SwiftUI
import AppKit

// NSTextField subclass that grabs focus and selects all as soon as it enters a window.
private final class AutoFocusTextField: NSTextField {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.window?.makeFirstResponder(self)
            self.currentEditor()?.selectAll(nil)
        }
    }
}

// NSViewRepresentable wrapping AutoFocusTextField.
// Uses controlTextDidEndEditing — fires for every blur: click elsewhere,
// Tab, Return, click another app — unlike @FocusState which only fires
// when focus moves to another SwiftUI-focusable element.
private struct NumberEditField: NSViewRepresentable {
    @Binding var value: Int
    var onEndEditing: () -> Void

    func makeNSView(context: Context) -> AutoFocusTextField {
        let field = AutoFocusTextField()
        field.delegate = context.coordinator
        field.stringValue = "\(value)"
        field.alignment = .right
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: NSFont.systemFontSize)
        return field
    }

    func updateNSView(_ nsView: AutoFocusTextField, context: Context) {
        context.coordinator.parent = self
        guard nsView.currentEditor() == nil else { return }
        nsView.stringValue = "\(value)"
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NumberEditField
        init(_ parent: NumberEditField) { self.parent = parent }

        func controlTextDidEndEditing(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            if let v = Int(field.stringValue), v > 0 {
                parent.value = v
            } else {
                field.stringValue = "\(parent.value)"
            }
            parent.onEndEditing()
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField,
                  let v = Int(field.stringValue), v > 0 else { return }
            parent.value = v
        }
    }
}

private struct HoverableTimeField: View {
    let label: String
    let unit: String
    @Binding var value: Int
    @State private var isHovered = false
    @State private var isEditing = false

    var body: some View {
        LabeledContent(label) {
            HStack(spacing: 6) {
                Group {
                    if isEditing {
                        NumberEditField(value: $value) { isEditing = false }
                    } else {
                        Text("\(value)")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .contentShape(Rectangle())
                            .onTapGesture { isEditing = true }
                    }
                }
                .frame(width: 54)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isEditing
                            ? Color(nsColor: .textBackgroundColor)
                            : (isHovered ? Color.accentColor.opacity(0.10) : Color.clear))
                        .animation(.easeInOut(duration: 0.12), value: isEditing)
                        .animation(.easeInOut(duration: 0.15), value: isHovered)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            isEditing ? Color.accentColor.opacity(0.55) :
                                (isHovered ? Color.accentColor.opacity(0.35) : Color.clear),
                            lineWidth: 1
                        )
                        .animation(.easeInOut(duration: 0.12), value: isEditing)
                        .animation(.easeInOut(duration: 0.15), value: isHovered)
                )
                .onHover { isHovered = $0 }

                Text(unit)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var scheduler: BreakScheduler
    @Environment(\.dismiss) private var dismiss

    @State private var draft: BreakSettings = .load()

    private var isActive: Bool { scheduler.state != .idle }

    private var microWorkMinutes: Binding<Int> {
        Binding(
            get: { draft.microWorkSeconds / 60 },
            set: { draft.microWorkSeconds = $0 * 60 }
        )
    }

    private var macroWorkMinutes: Binding<Int> {
        Binding(
            get: { draft.macroWorkSeconds / 60 },
            set: { draft.macroWorkSeconds = $0 * 60 }
        )
    }

    private var macroBreakMinutes: Binding<Int> {
        Binding(
            get: { draft.macroBreakSeconds / 60 },
            set: { draft.macroBreakSeconds = $0 * 60 }
        )
    }

    private var logo: NSImage? {
        guard let path = Bundle.main.path(forResource: "logo", ofType: "png", inDirectory: "resources") else { return nil }
        return NSImage(contentsOfFile: path)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with logo
            HStack(spacing: 10) {
                if let logoImage = logo {
                    Image(nsImage: logoImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Take A Break")
                        .font(.title2.bold())
                    Text("Protect your eyes and posture")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 16)

            onOffToggle
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            Form {
                Section("Micro break (eye rest)") {
                    HoverableTimeField(label: "Work for", unit: "minutes", value: microWorkMinutes)
                    HoverableTimeField(label: "Break for", unit: "seconds", value: $draft.microBreakSeconds)
                }

                Section("Macro break (long break)") {
                    HoverableTimeField(label: "Work for", unit: "minutes", value: macroWorkMinutes)
                    HoverableTimeField(label: "Break for", unit: "minutes", value: macroBreakMinutes)
                }

                Section("Overlay style") {
                    Picker("Style", selection: $draft.overlayStyle) {
                        Text("Simple").tag(OverlayStyle.simple)
                        Text("Animation").tag(OverlayStyle.animation)
                    }
                    .pickerStyle(.radioGroup)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack(spacing: 8) {
                Spacer()
                Button("Cancel") {
                    draft = .load()
                    dismiss()
                }
                .controlSize(.large)

                Button("Save") {
                    draft.save()
                    scheduler.settings = draft
                    dismiss()
                }
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(minWidth: 380, minHeight: 520)
    }

    private var onOffToggle: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isActive { scheduler.pause() } else { scheduler.start() }
            }
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isActive ? "On" : "Off")
                        .font(.headline.bold())
                        .foregroundStyle(isActive ? Color.green : Color.secondary)
                    Text(isActive ? "Breaks are scheduled" : "No breaks scheduled")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ZStack(alignment: isActive ? .trailing : .leading) {
                    Capsule()
                        .fill(isActive ? Color.green : Color(nsColor: .separatorColor))
                        .frame(width: 40, height: 22)
                    Circle()
                        .fill(.white)
                        .frame(width: 17, height: 17)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .padding(2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Color.green.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isActive ? Color.green.opacity(0.25) : Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
