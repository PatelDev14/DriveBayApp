//// Components/ClockPicker.swift
//import SwiftUI
//
//struct ClockPicker: View {
//    let title: String
//    @Binding var selection: String  // "HH:mm" format
//
//    @State private var showingPicker = false
//
//    private let hours = Array(0...23)
//    private let minutes = [0, 15, 30, 45]
//
//    private var isEmpty: Bool {
//        selection.isEmpty || selection == "--:--" || selection.count != 5
//    }
//
//    private var currentHour: Int {
//        Int(selection.prefix(2)) ?? 9
//    }
//
//    private var currentMinute: Int {
//        Int(selection.suffix(2)) ?? 0
//    }
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text(title)
//                .font(.headline)
//                .foregroundColor(.white.opacity(0.9))
//
//            Button {
//                showingPicker.toggle()
//            } label: {
//                HStack(spacing: 14) {
//                    Image(systemName: "clock.fill")
//                        .font(.title3)
//                        .foregroundStyle(DriveBayTheme.accent)
//
//                    Text(isEmpty ? "Tap to select time" : selection)
//                        .font(.system(size: isEmpty ? 19 : 23, weight: .bold, design: .rounded))
//                        .monospacedDigit()
//                        .foregroundColor(.white)
//                        .opacity(isEmpty ? 0.35 : 1.0)
//                        .italic(isEmpty)
//                        .lineLimit(1)
//                        .minimumScaleFactor(0.8)  // ← THIS IS THE MAGIC
//                }
//                .padding(.horizontal, 20)
//                .padding(.vertical, 18)
//                .frame(height: 64)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .background(Color.white.opacity(0.08))
//                .cornerRadius(18)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 18)
//                        .strokeBorder(DriveBayTheme.accent.opacity(0.7).gradient, lineWidth: 2.2)
//                )
//                .shadow(color: DriveBayTheme.glow.opacity(0.7), radius: 16, y: 8)
//            }
//            .buttonStyle(.plain)
//
//            // POPOVER — CLEAN & PERFECT
//            .popover(isPresented: $showingPicker) {
//                VStack(spacing: 24) {
//                    Text("Select Time")
//                        .font(.title2.bold())
//                        .foregroundColor(.white)
//
//                    HStack(spacing: 28) {
//                        Picker("Hour", selection: Binding(
//                            get: { currentHour },
//                            set: { h in
//                                let hs = String(format: "%02d", h)
//                                selection = selection.count == 5 ? hs + ":" + selection.suffix(2) : hs + ":00"
//                            }
//                        )) {
//                            ForEach(hours, id: \.self) {
//                                Text(String(format: "%02d", $0))
//                                    .font(.title2.monospacedDigit())
//                            }
//                        }
//                        .pickerStyle(.wheel)
//                        .frame(width: 100, height: 160)
//
//                        Text(":")
//                            .font(.system(size: 48, weight: .thin))
//                            .foregroundColor(.white.opacity(0.6))
//
//                        Picker("Minute", selection: Binding(
//                            get: { currentMinute },
//                            set: { m in
//                                let ms = String(format: "%02d", m)
//                                selection = selection.count == 5 ? selection.prefix(2) + ":" + ms : "09:" + ms
//                            }
//                        )) {
//                            ForEach(minutes, id: \.self) {
//                                Text(String(format: "%02d", $0))
//                                    .font(.title2.monospacedDigit())
//                            }
//                        }
//                        .pickerStyle(.wheel)
//                        .frame(width: 100, height: 160)
//                    }
//
////                    Button("Done") {
////                        showingPicker = false
////                    }
//
//                    Button("Done") {
//                        // THIS IS THE MAGIC FIX
//                        if selection.isEmpty || selection.count != 5 {
//                            selection = "09:00"  // fallback only when truly empty
//                        }
//                        showingPicker = false
//                    }                    .font(.title3.bold())
//                    .foregroundColor(.black)
//                    .frame(maxWidth: .infinity)
//                    .frame(height: 56)
//                    .background(DriveBayTheme.accent)
//                    .cornerRadius(16)
//                    .shadow(color: DriveBayTheme.glow, radius: 20)
//                }
//                .padding(24)
//                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 24)
//                        .strokeBorder(DriveBayTheme.accent.opacity(0.4).gradient, lineWidth: 1.5)
//                )
//                .padding()
//                .presentationCompactAdaptation(.popover)
//            }
//        }
//    }
//}
//
//#Preview {
//    VStack(spacing: 30) {
//        ClockPicker(title: "Start Time", selection: .constant(""))
//        ClockPicker(title: "End Time", selection: .constant("17:30"))
//        ClockPicker(title: "Long Time Test", selection: .constant("23:45"))
//    }
//    .padding()
//    .background(Color.black)
//}

// Components/ClockPicker.swift
import SwiftUI

struct ClockPicker: View {
    let title: String
    @Binding var selection: String  // "HH:mm" format

    @State private var showingPicker = false

    private let hours = Array(0...23)
    private let minutes = [0, 15, 30, 45]

    private var isEmpty: Bool {
        selection.isEmpty || selection == "--:--" || selection.count != 5
    }

    private var currentHour: Int {
        Int(selection.prefix(2)) ?? 9
    }

    private var currentMinute: Int {
        Int(selection.suffix(2)) ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            Button {
                showingPicker.toggle()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundStyle(DriveBayTheme.accent)

                    // THIS IS THE MAGIC — BLURRED TIME PLACEHOLDER
                    Text(isEmpty ? "07 : 00" : selection)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .opacity(isEmpty ? 0.28 : 1.0)     // Super soft blur
                        .italic(isEmpty)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .frame(height: 64)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.08))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(DriveBayTheme.accent.opacity(0.7).gradient, lineWidth: 2.2)
                )
                .shadow(color: DriveBayTheme.glow.opacity(0.7), radius: 16, y: 8)
            }
            .buttonStyle(.plain)

            // POPOVER — PERFECT
            .popover(isPresented: $showingPicker) {
                VStack(spacing: 24) {
                    Text("Select Time")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    HStack(spacing: 28) {
                        Picker("Hour", selection: Binding(
                            get: { currentHour },
                            set: { h in
                                let hs = String(format: "%02d", h)
                                selection = selection.count == 5 ? hs + ":" + selection.suffix(2) : hs + ":00"
                            }
                        )) {
                            ForEach(hours, id: \.self) {
                                Text(String(format: "%02d", $0))
                                    .font(.title2.monospacedDigit())
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 160)

                        Text(":")
                            .font(.system(size: 48, weight: .thin))
                            .foregroundColor(.white.opacity(0.6))

                        Picker("Minute", selection: Binding(
                            get: { currentMinute },
                            set: { m in
                                let ms = String(format: "%02d", m)
                                selection = selection.count == 5 ? selection.prefix(2) + ":" + ms : "09:" + ms
                            }
                        )) {
                            ForEach(minutes, id: \.self) {
                                Text(String(format: "%02d", $0))
                                    .font(.title2.monospacedDigit())
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100, height: 160)
                    }

                    Button("Done") {
                        if isEmpty {
                            selection = "09:00"  // fallback only if user didn't pick
                        }
                        showingPicker = false
                    }
                    .font(.title3.bold())
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DriveBayTheme.accent)
                    .cornerRadius(16)
                    .shadow(color: DriveBayTheme.glow, radius: 20)
                }
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(DriveBayTheme.accent.opacity(0.4).gradient, lineWidth: 1.5)
                )
                .padding()
                .presentationCompactAdaptation(.popover)
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        ClockPicker(title: "Start Time", selection: .constant(""))     // → –– : –– (blurred)
        ClockPicker(title: "End Time", selection: .constant("17:30"))  // → 17:30 (sharp)
        ClockPicker(title: "Test", selection: .constant("23:45"))      // → 23:45 (sharp)
    }
    .padding()
    .background(Color.black)
}
