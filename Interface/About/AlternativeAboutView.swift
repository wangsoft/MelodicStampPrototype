//
//  AlternativeAboutView.swift
//  Melodic Stamp
//
//  Created by Xinshao_Air on 2025/1/22.
//

import SwiftUI

struct AlternativeAboutView: View {
    var body: some View {
        let version = Bundle.main[.appVersion]
        let build = Bundle.main[.appBuild]
        let combined = "\(version) \(build)"

        VStack {
            ContinuousRippleEffectView {
                contentText(version: combined)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .multilineTextAlignment(.leading)
        .preferredColorScheme(.dark)
        .frame(width: 350, height: 150)
    }

    private func contentText(version: String) -> Text {
        let title = Text(verbatim: "Melodic Stamp ")
            .fontDesign(.serif)
            .font(.title)
            .bold()
        let preview = Text(verbatim: "Preview\n")
            .foregroundStyle(Color.white.opacity(0.45))
            .fontDesign(.serif)
            .font(.title)
            .italic()
        let repository = Text(verbatim: "\nOpen Sourced On GitHub\n")
            .fontDesign(.monospaced)
            .font(.subheadline)
        let version = Text(verbatim: version + "\n\n")
            .foregroundStyle(Color.white.opacity(0.45))
            .fontDesign(.monospaced)
            .font(.subheadline)
        let cement = Text(verbatim: "Cement")
            .font(.custom("SFPro-ExpandedLight", size: 12))
        let labs = Text(verbatim: " Labs\n")
            .font(.custom("SFPro-CompressedLight", size: 12))
        let copyright = Text(verbatim: "© 2024 → Future")
            .foregroundStyle(Color.white.opacity(0.45))
            .font(.custom("SFPro-CompressedLight", size: 12))

        return title + preview + repository + version + cement + labs + copyright
    }
}

#Preview {
    AlternativeAboutView()
}
