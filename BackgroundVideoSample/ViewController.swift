import UIKit
import AVFoundation

class ViewController: UIViewController {

    deinit {
        // 画面が破棄された時に監視をやめる
        if let observers = observers {
            NotificationCenter.default.removeObserver(observers.player)
            NotificationCenter.default.removeObserver(observers.willEnterForeground)
            observers.boundsObserver.invalidate()
        }
    }

    private var observers: (player: NSObjectProtocol, willEnterForeground: NSObjectProtocol, boundsObserver: NSKeyValueObservation)?

    var audioPlayer : AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let soundFilePath : String = Bundle.main.path(forResource: "whitenoise", ofType: "mp3")!
        let fileURL : URL = URL(fileURLWithPath: soundFilePath)
        
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
        }
        catch{
        }
        
        //numberOfLoopsに-1を指定すると無限ループする。
        audioPlayer.numberOfLoops = -1
        audioPlayer.play()

        // Bundle Resourcesからnoise.mp4を読み込んで再生
        let path = Bundle.main.path(forResource: "noise", ofType: "mp4")!
        let player = AVPlayer(url: URL(fileURLWithPath: path))
        player.actionAtItemEnd = .none // default: pause
        player.isMuted = false // default: false
        player.play()

        // AVPlayer用のLayerを生成
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.zPosition = -2
        view.layer.insertSublayer(playerLayer, at: 0)
        
        // 動画の上に重ねる半透明の黒いレイヤー
        let dimOverlay = CALayer()
        dimOverlay.frame = view.bounds
        dimOverlay.backgroundColor = UIColor.black.cgColor
        dimOverlay.zPosition = -1
        dimOverlay.opacity = 0.2
        view.layer.insertSublayer(dimOverlay, at: 0)

        // 最後まで再生したら最初から再生する
        let playerObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main) { [weak playerLayer] _ in
                playerLayer?.player?.seek(to: CMTime.zero)
                playerLayer?.player?.play()
        }

        // アプリがバックグラウンドから戻ってきた時に再生する
        let willEnterForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main) { [weak playerLayer] _ in
                playerLayer?.player?.play()
        }

        // 端末が回転した時に動画レイヤーのサイズを調整する
        let boundsObserver = view.layer.observe(\.bounds) { [weak playerLayer, weak dimOverlay] view, _ in
            DispatchQueue.main.async {
                playerLayer?.frame = view.bounds
                dimOverlay?.frame = view.bounds
            }
        }

        observers = (playerObserver, willEnterForegroundObserver, boundsObserver)
    }
    
}

