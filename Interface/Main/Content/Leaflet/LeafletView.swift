//
//  LeafletView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/13.
//

import Defaults
import DominantColors
import SwiftUI

struct LeafletView: View {
    // MARK: - Environments

    @Environment(FloatingWindowsModel.self) private var floatingWindows
    @Environment(KeyboardControlModel.self) private var keyboardControl
    @Environment(PlaylistModel.self) private var playlist
    @Environment(PlayerModel.self) private var player
    @Environment(MetadataEditorModel.self) private var metadataEditor
    @Environment(LyricsModel.self) private var lyrics
    @Environment(AudioVisualizerModel.self) private var audioVisualizer
    @Environment(GradientVisualizerModel.self) private var gradientVisualizer

    @Environment(\.appearsActive) private var appearsActive

    @FocusState private var isFocused: Bool

    @Namespace private var localNamespace

    @Default(.lyricsTypeSizes) private var typeSizes
    @Default(.lyricsMaxWidth) private var maxWidth

    // MARK: - Fields

    @State private var innerSize: CGSize = .zero
    @State private var isShowingLyrics: Bool = true
    @State private var isControlsHovering: Bool = false

    @State private var typeSize: DynamicTypeSize = Defaults[.lyricsTypeSize]
    @State private var interaction: AppleMusicLyricsViewInteractionModel = .init()

    // MARK: - Body

    var body: some View {
        @Bindable var floatingWindows = floatingWindows

        if !player.hasCurrentTrack {
            ExcerptView(tab: SidebarContentTab.leaflet)
        } else {
            VStack {
                if hasCover || hasLyrics {
                    HStack(spacing: 0) {
                        if hasCover {
                            Spacer(minLength: 0)
                        }

                        HStack(spacing: 50) {
                            // MARK: Cover

                            if hasCover, let cover {
                                coverView(cover)
                            }

                            // MARK: Lyrics

                            if hasLyrics, isShowingLyrics {
                                lyricsView()
                                    .transition(.blurReplace(.downUp))
                                    .dynamicTypeSize(typeSize)
                                    .frame(maxWidth: max(Double(maxWidth), innerSize.width / 2))
                            }
                        }

                        if !hasLyrics || !isShowingLyrics {
                            Spacer(minLength: 0)
                        }
                    }
                    .containerRelativeFrame(.horizontal, alignment: .center) { length, axis in
                        switch axis {
                        case .horizontal:
                            let padding = length * 0.1
                            return length - 2 * max(100, padding)
                        case .vertical:
                            return length
                        }
                    }
                    .onGeometryChange(for: CGSize.self) { proxy in
                        proxy.size
                    } action: { newValue in
                        innerSize = newValue
                    }
                    .overlay(alignment: .leading) {
                        Group {
                            if hasLyrics, isShowingLyrics {
                                LeafletLyricsControlsView(
                                    isHidden: $floatingWindows.isHidden,
                                    typeSize: $typeSize
                                )
                                .transition(.blurReplace(.downUp))
                                .environment(\.availableTypeSizes, typeSizes)
                                .onChange(of: typeSizes) { _, _ in
                                    typeSize = typeSize.dynamicallyClamped
                                }
                            }
                        }
                        .padding(12)
                        .alignmentGuide(.leading) { d in
                            d[.trailing]
                        }
                    }
                } else {
                    // Stops rendering lyrics
                    Color.clear
                }
            }
            .animation(.easeInOut, value: hasLyrics)
            .animation(.easeInOut, value: isShowingLyrics)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background {
                windowBackgroundView()
            }
            .focusable()
            .focusEffectDisabled()
            .focused($isFocused)
            .onChange(of: appearsActive, initial: true) { _, newValue in
                isFocused = newValue
            }

            // MARK: Lyrics

            // Don't extract this logic or modify the tasks!
            .onAppear {
                guard let track = playlist.currentTrack else { return }

                Task {
                    let raw = await track.metadata.poll(for: \.lyrics).current
                    await lyrics.read(raw)
                }
            }
            .onChange(of: playlist.currentTrack) { _, newValue in
                lyrics.clear(newValue?.url)
                guard let newValue else { return }

                Task {
                    let raw = await newValue.metadata.poll(for: \.lyrics).current
                    await lyrics.read(raw)
                }
            }

            // MARK: Color Scheme

            .colorScheme(.dark)

            // MARK: Keyboard Handlers

            // Handles [space / ⏎] -> toggle play / pause
            .onKeyPress(keys: [.space, .return], phases: .all) { key in
                keyboardControl.handlePlayPause(
                    phase: key.phase, modifiers: key.modifiers
                )
            }

            // Handles [← / →] -> adjust progress
            .onKeyPress(keys: [.leftArrow, .rightArrow], phases: .all) { key in
                let sign: FloatingPointSign = key.key == .leftArrow ? .minus : .plus

                return keyboardControl.handleProgressAdjustment(
                    phase: key.phase, modifiers: key.modifiers, sign: sign
                )
            }

            // Handles [j / l] -> adjust progress
            .onKeyPress(keys: ["j", "l"], phases: .all) { key in
                let sign: FloatingPointSign = key.characters == "j" ? .minus : .plus

                return keyboardControl.handleProgressAdjustment(
                    phase: key.phase, modifiers: key.modifiers, sign: sign
                )
            }

            // Handles [↑ / ↓] -> adjust volume
            .onKeyPress(keys: [.upArrow, .downArrow], phases: .all) { key in
                let sign: FloatingPointSign = key.key == .downArrow ? .minus : .plus

                return keyboardControl.handleVolumeAdjustment(
                    phase: key.phase, modifiers: key.modifiers, sign: sign
                )
            }

            // Handles [m] -> toggle muted
            .onKeyPress(keys: ["m"], phases: .down) { _ in
                player.isMuted.toggle()
                return .handled
            }
        }
    }

    private var cover: NSImage? {
        if
            let attachedPictures = playlist.currentTrack?.metadata[extracting: \.attachedPictures]?.current,
            let cover = ThumbnailMaker.getCover(from: attachedPictures)?.image {
            cover
        } else { nil }
    }

    private var hasCover: Bool { cover != nil }

    private var hasLyrics: Bool {
        !lyrics.lines.isEmpty
    }

    // MARK: - Cover View

    @ViewBuilder private func coverView(_ cover: NSImage) -> some View {
        @Bindable var player = player

        Group {
            if hasLyrics {
                VStack {
                    MusicCover(
                        images: [cover], hasPlaceholder: true,
                        cornerRadius: 12
                    )
                    .motionCard()
                }
                .onTapGesture {
                    isShowingLyrics.toggle()
                }
                .scaleEffect(player.isPlaying ? 1 : 0.85, anchor: .center)
            } else {
                VStack {
                    MusicCover(
                        images: [cover], hasPlaceholder: true,
                        cornerRadius: 12
                    )
                    .motionCard()
                }
                .onTapGesture {
                    isShowingLyrics.toggle()
                }
                .scaleEffect(player.isPlaying ? 1 : 0.85, anchor: .center)
            }
        }
        .matchedGeometryEffect(id: "cover", in: localNamespace)
        .containerRelativeFrame(.vertical, alignment: .center) { length, axis in
            switch axis {
            case .horizontal:
                length
            case .vertical:
                min(500, length * 0.5)
            }
        }
        .shadow(radius: player.isPlaying ? 20 : 10)
        .animation(.spring(duration: 0.65, bounce: 0.45, blendDuration: 0.75).delay(0.25), value: player.isPlaying)
    }

    // MARK: - Lyrics View

    @ViewBuilder private func lyricsView() -> some View {
        DisplayLyricsView(interactionState: $interaction.state)
            .overlay(alignment: .trailing) {
                Group {
                    if !interaction.state.isDelegated {
                        AppleMusicLyricsViewInteractionStateButton(
                            interactionState: $interaction.state,
                            progress: interaction.delegationProgress,
                            hasProgressRing: interaction.hasProgressRing && interaction.delegationProgress > 0
                        )
                        .tint(.white)
                        .transition(.blurReplace(.downUp))
                    }
                }
                .animation(.bouncy, value: interaction.state.isDelegated)
                .padding(12)
                .alignmentGuide(.trailing) { d in
                    d[.leading]
                }
            }
    }

    // MARK: - Window Background

    @ViewBuilder private func windowBackgroundView() -> some View {
        if hasCover {
            ChromaBackgroundView()
                .environment(player)
                .environment(audioVisualizer)
                .environment(gradientVisualizer)
                .overlay {
                    Color.black
                        .opacity(0.175)
                        .blendMode(.multiply)
                }
        } else {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)

                LinearGradient(
                    colors: [.clear, .accent],
                    startPoint: .top, endPoint: .bottom
                )
                .opacity(0.65)
                .brightness(-0.075)
                .blendMode(.multiply)
            }
        }
    }
}

#if DEBUG
    #Preview(traits: .modifier(PreviewEnvironmentsModifier())) {
        @Previewable @State var lyrics: LyricsModel = .init()

        LeafletView()
            .environment(lyrics)
    }
#endif
