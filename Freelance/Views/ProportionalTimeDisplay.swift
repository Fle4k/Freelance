//
//  ProportionalTimeDisplay.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct ProportionalTimeDisplay: View {
    let timeString: String
    let digitFontSize: CGFloat
    
    private var unitFontSize: CGFloat {
        // Apply the same proportional scaling as the main timer
        // Units are 80% of digit size (200/250 ratio from main timer)
        return digitFontSize * 0.8
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(parseTimeString(timeString), id: \.id) { component in
                // Digits
                Text(component.digits)
                    .font(.custom("Major Mono Display Regular", size: digitFontSize))
                    .foregroundColor(.primary)
                
                // Unit
                Text(component.unit)
                    .font(.custom("Major Mono Display Regular", size: unitFontSize))
                    .foregroundColor(.primary)
            }
        }
    }
    
    private func parseTimeString(_ timeString: String) -> [TimeComponent] {
        var components: [TimeComponent] = []
        var currentDigits = ""
        
        for character in timeString {
            if character.isNumber {
                currentDigits.append(character)
            } else {
                // Found a unit character
                if !currentDigits.isEmpty {
                    components.append(TimeComponent(
                        id: UUID(),
                        digits: currentDigits,
                        unit: String(character)
                    ))
                    currentDigits = ""
                }
            }
        }
        
        // Handle case where there are remaining digits (shouldn't happen with proper formatting)
        if !currentDigits.isEmpty {
            components.append(TimeComponent(
                id: UUID(),
                digits: currentDigits,
                unit: ""
            ))
        }
        
        return components
    }
}

struct TimeComponent {
    let id: UUID
    let digits: String
    let unit: String
}

#Preview {
    VStack(spacing: 20) {
        ProportionalTimeDisplay(timeString: "2h30m", digitFontSize: 20)
        ProportionalTimeDisplay(timeString: "1h45m30s", digitFontSize: 18)
        ProportionalTimeDisplay(timeString: "45m", digitFontSize: 16)
    }
    .padding()
}
