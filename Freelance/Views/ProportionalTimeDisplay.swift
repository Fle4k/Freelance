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
    
    var body: some View {
        Text(timeString)
            .font(.custom("Major Mono Display Regular", size: digitFontSize))
            .foregroundColor(.primary)
    }
}

#Preview {
    VStack(spacing: 20) {
        ProportionalTimeDisplay(timeString: "02:30:00", digitFontSize: 20)
        ProportionalTimeDisplay(timeString: "01:45:30", digitFontSize: 18)
        ProportionalTimeDisplay(timeString: "00:45:00", digitFontSize: 16)
    }
    .padding()
}
