import Foundation
import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

class NotesListViewController: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var notesTable: UITableView!

    var notes: [(stringID: String, title: String, updateTime: String)] = []
    var selectedNoteID: String?
    let databaseRef = Database.database().reference(withPath: "Users")

    override func viewDidLoad() {
        super.viewDidLoad()
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(longPress:)))
        self.view.addGestureRecognizer(longPress)


    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        notes = []
        getData()
    }

    func getData() {
        let userRef = databaseRef.child(Auth.auth().currentUser!.uid)
        let url = URL(string: "https://notesapp-2d98c.firebaseio.com/Users/\(Auth.auth().currentUser!.uid).json?print=pretty")
        if let Url = url {
            let request = URLRequest(url: Url)
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                        for item in json {
                            userRef.child(item.key).child("Title").observeSingleEvent(of: .value, with: { (titleSnapshot) in
                                userRef.child(item.key).child("UpdateTime").observeSingleEvent(of: .value, with: { (updateTimeSnapshot) in
                                    self.notes.append((stringID: item.key, title: titleSnapshot.value as! String, updateTime: updateTimeSnapshot.value as! String))
                                    self.notesTable.reloadData()
                                })
                            })
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            task.resume()
        }
    }

    @objc func handleLongPress(longPress: UILongPressGestureRecognizer) {
        if longPress.state == UIGestureRecognizer.State.began {

            let touchPoint = longPress.location(in: self.view)
            if let indexPath = self.notesTable.indexPathForRow(at: touchPoint) {
                let cell = self.notesTable.cellForRow(at: indexPath) as! NoteCell
                let alert = UIAlertController(title: "Delete Note?", message: nil, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Delete", style: .default) { (action) in
                    self.databaseRef.child(Auth.auth().currentUser!.uid).child(cell.stringID!).removeValue()
                    self.notes.remove(at: indexPath.row)
                    self.notesTable.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alert.addAction(okAction)
                alert.addAction(cancelAction)
                self.present(alert, animated: true)
            }
        }
    }

    @IBAction func addButtonPressed(sender: Any?) {
        let newNoteItem: (stringID: String, title: String) = (stringID: String(arc4random()), title: "")
        databaseRef.child(Auth.auth().currentUser!.uid).child(newNoteItem.stringID).child("Title").setValue("")
        databaseRef.child(Auth.auth().currentUser!.uid).child(newNoteItem.stringID).child("NoteBody").setValue("")
        databaseRef.child(Auth.auth().currentUser!.uid).child(newNoteItem.stringID).child("UpdateTime").setValue("")
        self.selectedNoteID = newNoteItem.stringID
        self.performSegue(withIdentifier: "detailView", sender: self)

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailView" {
            let nextView = segue.destination as! NoteDetailViewController
            if let selectedNote = self.selectedNoteID {
                nextView.selectedNoteId = selectedNote
                self.selectedNoteID = nil
            }
        }
    }

    @IBAction func unwindToTable(segue: UIStoryboardSegue) {
        
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 105
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NoteCell
        cell.titleLabel.text! = String(notes[indexPath.row].title)
        if cell.titleLabel.text! == "" {
            cell.titleLabel.text! = "[No Title]"
        }
        cell.stringID = notes[indexPath.row].stringID
        cell.updateTimeLabel.text = notes[indexPath.row].updateTime
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if notes.count == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        } else {
            self.selectedNoteID = notes[indexPath.row].stringID
            tableView.deselectRow(at: indexPath, animated: true)
            self.performSegue(withIdentifier: "detailView", sender: self)
        }
    }
}
