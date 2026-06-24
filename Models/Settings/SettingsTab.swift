//
//  SettingsTab.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/5.
//

import Foundation
import SFSafeSymbols
import SwiftUI

enum SettingsTab: Hashable, Equatable, Identifiable, CaseIterable {
    case appearance
    case visualization
    case lyrics

    case launchBehaviors
    case performance

    case feedback

    var id: Self { self }

    var systemSymbol: SFSymbol {
        switch self {
        case .appearance: .paintbrushFill
        case .visualization: .waveform
        case .lyrics: .musicNoteList
        case .launchBehaviors: .airplaneDeparture
        case .performance: .gaugeWithDotsNeedle67percent
        case .feedback: .infoBubble
        }
    }

    var color: Color {
        switch self {
        case .appearance: .accent
        case .visualization: .pink
        case .lyrics: .orange
        case .launchBehaviors: .blue
        case .performance: .green
        case .feedback: .gray
        }
    }

    var name: String {
        switch self {
        case .appearance: String(localized: "Appearance")
        case .visualization: String(localized: "Visualization")
        case .lyrics: String(localized: "Lyrics")
        case .launchBehaviors: String(localized: "Launch Behaviors")
        case .performance: String(localized: "Performance")
        case .feedback: String(localized: "Feedback")
        }
    }
}
