//
//  RealtimeAnalyzerTests.swift
//  MelodicStamp
//
//  Created by OpenAI on 2026/6/22.
//

@testable import MelodicStamp
import Testing

@Suite struct RealtimeAnalyzerTests {
    @Test func generatesLogarithmicBandsEndingAtRequestedFrequency() {
        let bands = RealtimeAnalyzer.frequencyBands(
            startFrequency: 80,
            endFrequency: 18_000,
            count: 80
        )

        #expect(bands.count == 80)
        #expect(bands.first?.lowerFrequency == 80)
        #expect(bands.last?.upperFrequency == 18_000)

        for pair in zip(bands, bands.dropFirst()) {
            #expect(pair.0.upperFrequency == pair.1.lowerFrequency)
            #expect(pair.0.lowerFrequency < pair.0.upperFrequency)
        }
    }

    @Test func frequencyWeightsUseProvidedSampleRate() {
        let weights44100 = RealtimeAnalyzer.frequencyWeights(sampleRate: 44_100, fftSize: 2048)
        let weights48000 = RealtimeAnalyzer.frequencyWeights(sampleRate: 48_000, fftSize: 2048)

        #expect(weights44100.count == 1024)
        #expect(weights48000.count == 1024)
        #expect(weights44100[1] != weights48000[1])
    }
}
