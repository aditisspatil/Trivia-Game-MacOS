//
//  Audio.swift
//  Trivia
//
//  Created by Aditi Patil on 6/9/26.
//
import AVFoundation
import Combine

class AudioManager: ObservableObject {
    var player: AVAudioPlayer?

    func playSound(soundName: String, fileExtension: String) {
        // 1. Find the file in your app bundle
        guard let url = Bundle.main.url(forResource: soundName, withExtension: fileExtension) else {
            print("Could not find the audio file!")
            return
        }

        do {
            // 2. Load and play the file
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("Audio playback failed: \(error.localizedDescription)")
        }
    }
    
    func stopSound() {
            player?.stop()
        }
}
