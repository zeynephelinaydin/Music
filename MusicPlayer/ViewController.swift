// ViewController.swift
import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var table: UITableView!
    @IBOutlet weak var favorilerButton: UIButton!

    var songs = [Song]()

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewController.loadFavorites()
        loadSongsFromJSON()
        table.delegate = self
        table.dataSource = self
    }

    func loadSongsFromJSON() {
        guard let path = Bundle.main.path(forResource: "songs", ofType: "json") else {
            print("JSON dosyası bulunamadı")
            return
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decodedSongs = try JSONDecoder().decode([Song].self, from: data)
            self.songs = decodedSongs
        } catch {
            print("JSON yükleme hatası: \(error.localizedDescription)")
        }
    }

    static var sharedFavorites: [Song] = [] {
        didSet {
            saveFavorites()
        }
    }

    static func saveFavorites() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(sharedFavorites) {
            UserDefaults.standard.set(encoded, forKey: "favorites")
        }
    }

    static func loadFavorites() {
        if let savedData = UserDefaults.standard.data(forKey: "favorites") {
            let decoder = JSONDecoder()
            if let loadedFavorites = try? decoder.decode([Song].self, from: savedData) {
                sharedFavorites = loadedFavorites
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let song = songs[indexPath.row]
        cell.textLabel?.text = song.name
        cell.detailTextLabel?.text = song.albumName
        cell.accessoryType = .disclosureIndicator

        let imageSize = CGSize(width: 80, height: 80)
        if let image = UIImage(named: song.imageName) {
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: imageSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            cell.imageView?.image = resizedImage
        }

        cell.textLabel?.font = UIFont(name: "Helvetica-Bold", size: 18)
        cell.detailTextLabel?.font = UIFont(name: "Helvetica", size: 16)

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let position = indexPath.row
        guard let vc = storyboard?.instantiateViewController(identifier: "player") as? PlayerViewController else { return }
        vc.songs = songs
        vc.position = position
        present(vc, animated: true)
    }

    @IBAction func didTapFavoriler(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "favoritesVC") as? FavoritesViewController {
            vc.favorites = ViewController.sharedFavorites
            present(vc, animated: true, completion: nil)
        }
    }
}

struct Song: Codable {
    let name: String
    let albumName: String
    let singerName: String
    let imageName: String
    let trackName: String
}
