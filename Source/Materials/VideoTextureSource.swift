//
//  VideoTextureSource.swift
//  Satin
//
//  Created by Mark Dawson on 4/19/20.
//

import AVFoundation

public final class VideoTextureSource {
    private let player: AVPlayer
    private let playerItemVideoOutput: AVPlayerItemVideoOutput
    private let textureCache: CVMetalTextureCache

    public init?(context: Context, videoUrl: URL) {
        var texCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(
            kCFAllocatorDefault,
            nil,
            context.device,
            nil,
            &texCache
            ) != kCVReturnSuccess {
            print("Unable to allocate texture cache.")
            return nil
        }

        if texCache == nil {
            print("Texture cache was not initialized")
            return nil
        }
        self.textureCache = texCache!

        let asset = AVURLAsset(url: videoUrl)

        playerItemVideoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA)
        ])

        let playerItem = AVPlayerItem(asset: asset)
        playerItem.add(playerItemVideoOutput)

        player = AVPlayer(playerItem: playerItem)
        player.actionAtItemEnd = .none
    }

    public func play(repeat: Bool) {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: self.player.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.player.seek(to: CMTime.zero)
            self?.player.play()
        }

        player.play()
    }

    public func pause() {
        player.pause()
    }

    public func createTexture(hostTime: CFTimeInterval?) -> MTLTexture? {
        var currentTime = CMTime.invalid
        currentTime = playerItemVideoOutput.itemTime(forHostTime: hostTime ?? CACurrentMediaTime())

        guard playerItemVideoOutput.hasNewPixelBuffer(forItemTime: currentTime),
            let pixelBuffer = playerItemVideoOutput.copyPixelBuffer(
                forItemTime: currentTime,
                itemTimeForDisplay: nil) else {
                    return nil
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            self.textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &cvTextureOut
        )

        guard let cvTexture = cvTextureOut, let inputTexture = CVMetalTextureGetTexture(cvTexture) else {
            print("Failed to create metal texture")
            return nil
        }
        return inputTexture
    }
}
