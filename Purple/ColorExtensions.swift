//
//  ColorExtensions.swift
//  Purple
//
//  Created by Jimmy Bosse on 9/20/25.
//

import SwiftUI

extension Color {
    static let purplePrimary = Color(red: 0.6, green: 0.2, blue: 0.8)
    static let purpleSecondary = Color(red: 0.7, green: 0.3, blue: 0.9)
    static let purpleLight = Color(red: 0.85, green: 0.7, blue: 0.95)
    static let purpleDark = Color(red: 0.4, green: 0.1, blue: 0.6)

    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)

    static let cardBackground = Color(.systemBackground)
    static let cardShadow = Color.black.opacity(0.1)
}

extension View {
    func cardStyle() -> some View {
        self
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
    }

    func purpleButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.purplePrimary, Color.purpleSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(10)
    }
}
