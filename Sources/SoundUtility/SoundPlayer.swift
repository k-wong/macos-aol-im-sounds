import AVFoundation
import Foundation
import OSLog

final class SoundPlayer: @unchecked Sendable {
    private let logger = AppLog.logger("sound.player")
    private let queue = DispatchQueue(label: "aim.sound.player", qos: .userInitiated)
    private var players: [SoundEvent: AVAudioPlayer] = [:]

    func play(_ event: SoundEvent) {
        queue.async { [weak self] in
            self?.playSynchronously(event)
        }
    }

    func invalidate(_ event: SoundEvent) {
        queue.sync {
            players[event] = nil
        }
    }

    private func playSynchronously(_ event: SoundEvent) {
        do {
            guard let player = try player(for: event) else {
                return
            }
            if player.isPlaying {
                player.stop()
            }
            player.currentTime = 0
            player.prepareToPlay()
            player.play()
        } catch {
            logger.error("Failed to play \(event.rawValue, privacy: .public): \(String(describing: error), privacy: .public)")
        }
    }

    private func player(for event: SoundEvent) throws -> AVAudioPlayer? {
        if let player = players[event] {
            return player
        }

        guard let url = AppSoundLibrary.configuredSoundURL(for: event) else {
            return nil
        }

        let player = try AVAudioPlayer(contentsOf: url)
        player.prepareToPlay()
        players[event] = player
        return player
    }
}
