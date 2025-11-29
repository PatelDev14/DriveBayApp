//
//  ClockPicker.swift
//  DriveBayApp
//
//  Created by Dev Patel on 2025-11-28.
//

// Components/ClockPicker.swift
import SwiftUI

struct ClockPicker: View {
    let title: String
    @Binding var selection: String  // Expected format: "HH:mm" (e.g., "09:30")

    @State private var showingPicker = false

    private let hours = Array(0...23)
    private let minutes = [0, 15, 30, 45]

    private var displayTime: String {
        selection.isEmpty || selection == "--:--" ? "--:--" : selection
    }

    private var currentHour: Int {
        Int(selection.prefix(2)) ?? 9
    }

    private var currentMinute: Int {
        Int(selection.suffix(2)) ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())

            Button {
                showingPicker.toggle()
            } label: {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.indigo)

                    Text(displayTime)
                        .font(.body.monospacedDigit())
                        .foregroundColor(selection.count == 5 ? .primary : .secondary)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingPicker) {
                VStack(spacing: 16) {
                    HStack(spacing: 0) {
                        Picker("Hour", selection: Binding(
                            get: { currentHour },
                            set: { selection = String(format: "%02d", $0) + ":" + selection.suffix(2) }
                        )) {
                            ForEach(hours, id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 140)

                        Text(":")
                            .font(.largeTitle.bold())
                            .foregroundColor(.secondary)

                        Picker("Minute", selection: Binding(
                            get: { currentMinute },
                            set: { selection = selection.prefix(2) + ":" + String(format: "%02d", $0) }
                        )) {
                            ForEach(minutes, id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 140)
                    }

                    Button("Done") {
                        if selection.count != 5 { selection = "09:00" }
                        showingPicker = false
                    }
                    .font(.headline)
                    .foregroundColor(.indigo)
                    .padding(.bottom, 8)
                }
                .padding()
                .presentationCompactAdaptation(.popover)
            }
        }
    }
}

#Preview {
    ClockPicker(title: "Start Time", selection: .constant("14:30"))
        .padding()
        .background(Color(.systemBackground))
}
