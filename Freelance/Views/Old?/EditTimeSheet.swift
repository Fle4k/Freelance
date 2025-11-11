//
//  EditTimeSheet.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct EditTimeSheet: View {
    let period: StatisticsPeriod
    let currentTime: String
    @Binding var isPresented: Bool
    let customTitle: String?
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var hoursText: String = ""
    @State private var minutesText: String = ""
    @State private var isHoursFocused: Bool = true
    @State private var originalHoursText: String = ""
    @State private var originalMinutesText: String = ""
    
    private var periodTitle: String {
        if let customTitle = customTitle {
            return customTitle
        }
        
        switch period {
        case .today: return "edit this day"
        case .thisWeek: return "edit this week"
        case .thisMonth: return "edit this month"
        default: return "edit time"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer(minLength: 60)
                
                VStack(spacing: 30) {
                    // Title matching overview style
                    Text(periodTitle)
                        .font(.custom("Major Mono Display Regular", size: 18))
                        .foregroundColor(.secondary)
                    
                    // Show current total time
                    VStack(spacing: 10) {
                        Text("current total")
                            .font(.custom("Major Mono Display Regular", size: 16))
                            .foregroundColor(.secondary)
                        
                        ProportionalTimeDisplay(
                            timeString: currentTime,
                            digitFontSize: 20
                        )
                    }
                    .padding(.bottom, 10)
                    
                    // Time input section with proper spacing
                    VStack(spacing: 20) {
                        Spacer()
                        // Hours row
                        HStack {
                            Text("hours")
                                .font(.custom("Major Mono Display Regular", size: 17))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            SelectAllTextField(
                                text: $hoursText,
                                shouldBecomeFirstResponder: isHoursFocused
                            )
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                            .padding(.horizontal, 8)
                        }
                        
                        // Minutes row
                        HStack {
                            Text("minutes")
                                .font(.custom("Major Mono Display Regular", size: 17))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            SelectAllTextField(
                                text: $minutesText,
                                shouldBecomeFirstResponder: false
                            )
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                            .padding(.horizontal, 8)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    // Buttons
                    VStack(spacing: 15) {
                        Button(action: saveTime) {
                            Text("save")
                                .font(.custom("Major Mono Display Regular", size: 18))
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: { isPresented = false }) {
                            Text("cancel")
                                .font(.custom("Major Mono Display Regular", size: 18))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
            }
            .themedBackground()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupInitialValues()
        }
    }
    
    private func setupInitialValues() {
        let currentTime = TimeTracker.shared.getTotalHours(for: period)
        let hours = Int(currentTime)
        let minutes = Int((currentTime - Double(hours)) * 60)
        
        hoursText = hours > 0 ? "\(hours)" : ""
        minutesText = minutes > 0 ? "\(minutes)" : ""
        
        // Store original values for comparison
        originalHoursText = hoursText
        originalMinutesText = minutesText
        
        // Focus on hours field initially
        isHoursFocused = true
    }
    
    private func hasChanges() -> Bool {
        return hoursText != originalHoursText || minutesText != originalMinutesText
    }
    
    private func saveTime() {
        let hours = Int(hoursText) ?? 0
        let minutes = Int(minutesText) ?? 0
        let totalSeconds = TimeInterval(hours * 3600 + minutes * 60)
        
        print("💾 SaveTime called - Hours: '\(hoursText)', Minutes: '\(minutesText)'")
        print("💾 Converted - Hours: \(hours), Minutes: \(minutes), TotalSeconds: \(totalSeconds)")
        print("💾 Period: \(period)")
        
        switch period {
        case .today:
            TimeTracker.shared.editTime(for: .today, newTime: totalSeconds)
        case .thisWeek:
            TimeTracker.shared.editTime(for: .thisWeek, newTime: totalSeconds)
        case .thisMonth:
            TimeTracker.shared.editTime(for: .thisMonth, newTime: totalSeconds)
        default:
            break
        }
        
        isPresented = false
    }
}

struct SelectAllTextField: UIViewRepresentable {
    @Binding var text: String
    let shouldBecomeFirstResponder: Bool
    
    init(text: Binding<String>, shouldBecomeFirstResponder: Bool = false) {
        self._text = text
        self.shouldBecomeFirstResponder = shouldBecomeFirstResponder
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.textAlignment = .center
        textField.borderStyle = .none
        textField.backgroundColor = UIColor.clear
        
        // Apply custom font
        if let customFont = UIFont(name: "Major Mono Display Regular", size: 20) {
            textField.font = customFont
        }
        
        // Set text color to match SwiftUI primary color
        textField.textColor = UIColor.label
        
        // Set keyboard type to number pad
        textField.keyboardType = .numberPad
        
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        // Only update if text has actually changed to avoid cursor jumping
        if uiView.text != text {
            uiView.text = text
        }
        
        // Auto-focus if this is the hours field
        if shouldBecomeFirstResponder && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SelectAllTextField

        init(_ parent: SelectAllTextField) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            // Select all text when editing begins
            DispatchQueue.main.async {
                textField.selectAll(nil)
            }
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            // Only update when there's an actual text change, not just selection change
            if textField.text != parent.text {
                parent.text = textField.text ?? ""
            }
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let newText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
            
            print("🔄 Text changing - Old: '\(textField.text ?? "")', New: '\(newText)'")
            
            // Update parent binding immediately
            DispatchQueue.main.async {
                self.parent.text = newText
                print("🔄 Updated parent binding to: '\(newText)'")
            }
            
            return true
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            // Ensure final value is captured when editing ends
            let finalText = textField.text ?? ""
            parent.text = finalText
            print("✅ Text editing ended - Final value: '\(finalText)'")
        }
    }
}

#Preview {
    EditTimeSheet(
        period: .today,
        currentTime: "2h30m",
        isPresented: .constant(true),
        customTitle: nil
    )
}
