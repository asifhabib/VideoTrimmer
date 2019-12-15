//
//  ViewController.swift
//  VideoTrimmer
//
//  Created by kyle.jo on 07/01/2019.
//  Copyright © 2019 kyle.jo. All rights reserved.
//

import AVFoundation
import UIKit
import MobileCoreServices // kUTTYPEMovie

class PlayVideoViewController: UIViewController {

    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var trimmerView: TrimmerView!
    @IBOutlet weak var rangeLabel: UILabel!

    var playerLayer: AVPlayerLayer?
    var playbackTimeCheckerTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        trimmerView.delegate = self
    }

    @IBAction func playVideo(_ sender: UIButton) {
        guard let player = playerLayer?.player else { return }
        let bartime = trimmerView.positionBarTime
        player.play()
        player.seek(to: bartime)
        startPlaybackTimeChecker()
    }

    @IBAction func openAction(_ sender: Any) {
        VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
    }

    @IBAction func stopAction(_ sender: Any) {
        guard let player = playerLayer?.player else { return }
        player.pause()
        stopPlaybackTimeChecker()
    }

    func startPlaybackTimeChecker() {
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 1.0 / 60.0, target: self, selector: #selector(onPlaybackTimeChecker), userInfo: nil, repeats: true)
        RunLoop.main.add(playbackTimeCheckerTimer!, forMode: .common)
    }

    func stopPlaybackTimeChecker() {
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }

    @objc
    func onPlaybackTimeChecker() {

        guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime, let player = playerLayer?.player else {
            return
        }

        let playBackTime = player.currentTime()
        trimmerView.seek(to: playBackTime)
        currentTime.text = "\(String(format: "%.1f", playBackTime.seconds))s"
        if playBackTime >= endTime {
            player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            trimmerView.seek(to: startTime)
            player.pause()
        }
    }

}

extension PlayVideoViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard
            let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String, mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL else {
                return
        }

        dismiss(animated: true) {
            self.prepareToPlay(url: url)
        }
    }

    func prepareToPlay(url: URL) {
        playerLayer?.removeFromSuperlayer()
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = playerView.frame
        playerView.layer.insertSublayer(playerLayer!, at: 0)
        playerLayer?.frame = playerView.bounds
        playerLayer?.layoutIfNeeded()
        trimmerView.changeAsset(to: playerItem.asset)
    }
}

extension PlayVideoViewController: TrimmerViewDelegate {
    func didChangeSelectedRange(to range: CMTimeRange) {
        rangeLabel.text = String(format: "%.1f", range.duration.seconds) + "s"
    }

    func willBeginChangePosition(to time: CMTime) {
        playerLayer?.player?.pause()
        stopPlaybackTimeChecker()
    }

    func didChangePosition(to time: CMTime) {
        playerLayer?.player?.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }

    func didEndChangePosition(to time: CMTime) {
        playerLayer?.player?.play()
        startPlaybackTimeChecker()
    }
}

// MARK: - UINavigationControllerDelegate
extension PlayVideoViewController: UINavigationControllerDelegate {

}
