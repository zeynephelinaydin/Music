import UIKit

class FavoritesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var table: UITableView!
    
    var favorites: [Song] = []
    var selectedIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        table.delegate = self
        table.dataSource = self
    }

    // Favori şarkı sayısı
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }

    // Hücreleri doldur
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "favcell", for: indexPath)

        let song = favorites[indexPath.row]
        cell.textLabel?.text = song.name
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        cell.detailTextLabel?.text = "\(song.albumName) · \(song.singerName)"
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14)
        cell.detailTextLabel?.textColor = UIColor.darkGray
        cell.accessoryType = .disclosureIndicator

        let imageSize = CGSize(width: 80, height: 80)
        if let image = UIImage(named: song.imageName) {
            UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: imageSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            cell.imageView?.image = resizedImage
        } else {
            cell.imageView?.image = UIImage(systemName: "music.note")
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.row
        performSegue(withIdentifier: "playFromFavorites", sender: self)
    }

    // Segue'ye hazırlan
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "playFromFavorites",
           let destination = segue.destination as? PlayerViewController,
           let indexPath = table.indexPathForSelectedRow {
            destination.songs = favorites
            destination.position = indexPath.row
        }
    }

    // Hücre yüksekliğini ayarla - ViewController ile aynı
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    // Favorilerden silme
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            favorites.remove(at: indexPath.row)
            table.deleteRows(at: [indexPath], with: .automatic)
            
            // Silinen şarkıyı shared favorites'den de kaldır
            ViewController.sharedFavorites = favorites
        }
    }
    
    // Kaydırınca çıkan "Delete" yazısını "Sil" yap
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Sil"
    }
}
