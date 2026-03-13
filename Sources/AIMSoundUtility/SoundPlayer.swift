import AVFoundation
import Foundation

final class SoundPlayer: @unchecked Sendable {
    private let bundle: Bundle
    private let queue = DispatchQueue(label: "aim.sound.player")
    private var activePlayers: [AVAudioPlayer] = []

    init(bundle: Bundle = .module) {
        self.bundle = bundle
    }

    func play(_ event: SoundEvent) {
        queue.async { [weak self] in
            self?.playSynchronously(event)
        }
    }

    private func playSynchronously(_ event: SoundEvent) {
        guard let url = bundle.url(forResource: resourceName(for: event), withExtension: "mp3") else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()

            activePlayers.removeAll { !$0.isPlaying }
            activePlayers.append(player)
        } catch {
            NSLog("Failed to play %@: %@", event.rawValue, String(describing: error))
        }
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
