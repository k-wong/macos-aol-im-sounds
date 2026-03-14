import AVFoundation
import Foundation
import OSLog

final class SoundPlayer: @unchecked Sendable {
    private let bundle: Bundle
    private let logger = AppLog.logger("sound.player")
    private let queue = DispatchQueue(label: "aim.sound.player", qos: .userInitiated)
    private var players: [SoundEvent: AVAudioPlayer] = [:]

    init(bundle: Bundle = AppResources.bundle()) {
        self.bundle = bundle
    }

    func play(_ event: SoundEvent) {
        queue.async { [weak self] in
            self?.playSynchronously(event)
        }
    }

    private func playSynchronously(_ event: SoundEvent) {
        do {
            let player = try player(for: event)
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

    private func player(for event: SoundEvent) throws -> AVAudioPlayer {
        if let player = players[event] {
            return player
        }

        guard let url = bundle.url(forResource: resourceName(for: event), withExtension: "mp3") else {
            throw NSError(domain: "AIMSoundUtility.SoundPlayer", code: 1)
        }

        let player = try AVAudioPlayer(contentsOf: url)
        player.prepareToPlay()
        players[event] = player
        return player
    }

    private func resourceName(for event: SoundEvent) -> String {
        switch event {
        case .exit:
            return "aim-exit"
        case .open:
            return "aim-open"
        case .message:
            return "aim-message"
        }
    }
}
