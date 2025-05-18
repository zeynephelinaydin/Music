import UIKit
import AVFoundation

class PlayerViewController: UIViewController, AVAudioPlayerDelegate {

    // MARK: - AVPlayer
    var player: AVAudioPlayer?
    var isPlaying = true
    var isShuffle = false
    var lastVolume: Float = 0.5
    var progressTimer: Timer?
    var shuffledOrder: [Int] = []
    var shuffledIndex: Int = 0

    // MARK: - Data
    public var position: Int = 0
    public var songs: [Song] = []

    // MARK: - IBOutlets
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet var holder: UIView!
    @IBOutlet var albumImageView: UIImageView!
    @IBOutlet var songNameLabel: UILabel!
    @IBOutlet var albumNameLabel: UILabel!
    @IBOutlet var singerNameLabel: UILabel!
    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var shuffleButton: UIButton!
    @IBOutlet var rewindButton: UIButton!
    @IBOutlet var forwardButton: UIButton!
    @IBOutlet var previousButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var volumeSlider: UISlider!
    @IBOutlet var lowVolumeIcon: UIImageView!
    @IBOutlet var highVolumeIcon: UIImageView!
    @IBOutlet var currentTimeLabel: UILabel!
    @IBOutlet var durationLabel: UILabel!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupShuffle()
        refreshAndPlay()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.stop()
        stopProgressTimer()
    }

    // MARK: - Setup Shuffle
    func setupShuffle() {
        if isShuffle {
            shuffledOrder = Array(0..<songs.count).shuffled()
            shuffledIndex = shuffledOrder.firstIndex(of: position) ?? 0
        }
    }

    // MARK: - Configure Player & UI
    func configure() {
        guard songs.indices.contains(position) else { return }
        let song = songs[position]

        guard let path = Bundle.main.path(forResource: song.trackName, ofType: "mp3") else {
            print("❌ MP3 dosyası bulunamadı")
            return
        }

        do {
            let url = URL(fileURLWithPath: path)
            try AVAudioSession.sharedInstance().setMode(.default)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = lastVolume
            player?.prepareToPlay()
        } catch {
            print("❌ Ses oynatma hatası: \(error.localizedDescription)")
        }

        albumImageView.image = UIImage(named: song.imageName)
        songNameLabel.text = song.name
        albumNameLabel.text = song.albumName
        singerNameLabel.text = song.singerName

        shuffleButton.tintColor = isShuffle ? .systemBlue : .gray
        volumeSlider.value = lastVolume
        currentTimeLabel.text = "00:00"
        durationLabel.text = formatTime(player?.duration ?? 0)

        updateFavoriteIcon()
    }

    // MARK: - Favorite Handling
    func updateFavoriteIcon() {
        let current = songs[position]
        if ViewController.sharedFavorites.contains(where: { $0.name == current.name }) {
            favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            favoriteButton.tintColor = .systemBlue
        } else {
            favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
            favoriteButton.tintColor = .white
        }
    }

    @IBAction func didTapFavoriteButton(_ sender: UIButton) {
        let current = songs[position]
        if let index = ViewController.sharedFavorites.firstIndex(where: { $0.name == current.name }) {
            ViewController.sharedFavorites.remove(at: index)
        } else {
            ViewController.sharedFavorites.append(current)
        }
        updateFavoriteIcon()
    }

    // MARK: - Playback Controls
    @IBAction func didTapPlayPause(_ sender: UIButton) {
        if isPlaying {
            player?.pause()
            stopProgressTimer()
        } else {
            player?.play()
            startProgressTimer()
        }
        isPlaying.toggle()
        updatePlayPauseButtonIcon()
    }

    @IBAction func didTapShuffle(_ sender: UIButton) {
        isShuffle.toggle()
        shuffleButton.tintColor = isShuffle ? .systemBlue : .gray
        setupShuffle()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @IBAction func didTapRewind(_ sender: UIButton) {
        guard let player = player else { return }
        player.currentTime = max(player.currentTime - 15, 0)
        updateCurrentTimeLabel()
    }

    @IBAction func didTapForward(_ sender: UIButton) {
        guard let player = player else { return }
        player.currentTime = min(player.currentTime + 15, player.duration)
        updateCurrentTimeLabel()
    }

    @IBAction func didTapPrevious(_ sender: UIButton) {
        if isShuffle {
            shuffledIndex = (shuffledIndex - 1 + shuffledOrder.count) % shuffledOrder.count
            position = shuffledOrder[shuffledIndex]
        } else {
            position = (position - 1 + songs.count) % songs.count
        }
        refreshAndPlay()
    }

    @IBAction func didTapNext(_ sender: UIButton) {
        if isShuffle {
            shuffledIndex = (shuffledIndex + 1) % shuffledOrder.count
            position = shuffledOrder[shuffledIndex]
        } else {
            position = (position + 1) % songs.count
        }
        refreshAndPlay()
    }

    @IBAction func volumeSliderChanged(_ sender: UISlider) {
        lastVolume = sender.value
        player?.volume = lastVolume
    }

    func updatePlayPauseButtonIcon() {
        let config = UIImage.SymbolConfiguration(pointSize: 44)
        let iconName = isPlaying ? "pause.circle.fill" : "play.circle.fill"
        playPauseButton.setImage(UIImage(systemName: iconName)?.withConfiguration(config), for: .normal)
    }

    // MARK: - Timer Management
    func refreshAndPlay() {
        player?.stop()
        stopProgressTimer()
        configure()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.player?.play()
            self.isPlaying = true
            self.updatePlayPauseButtonIcon()
            self.startProgressTimer()
        }
    }

    func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCurrentTimeLabel), userInfo: nil, repeats: true)
    }

    func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    @objc func updateCurrentTimeLabel() {
        currentTimeLabel.text = formatTime(player?.currentTime ?? 0)
    }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        didTapNext(nextButton)
    }
}
