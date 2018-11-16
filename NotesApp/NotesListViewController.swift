import Foundation
import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import RNCryptor

class NotesListViewController: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var notesTable: UITableView!
    @IBOutlet var logoutButton: UIButton!

    var notes: Array<Note> = []
    //var notes: [(stringID: String, title: String, updateTime: String)] = []
    var selectedNote: Note?
    var selectedCell: UITableViewCell?
    var key: String?
    let databaseRef = Database.database().reference(withPath: "Users")

    override func viewDidLoad() {
        super.viewDidLoad()
        logoutButton.layer.borderWidth = 1.0
        logoutButton.layer.borderColor = logoutButton.titleColor(for: .normal)?.cgColor
        logoutButton.layer.cornerRadius = 5.0
        logoutButton.clipsToBounds = true
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(longPress:)))
        self.view.addGestureRecognizer(longPress)
        getData()


    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }

    func getData() {
        let userRef = databaseRef.child(Auth.auth().currentUser!.uid)
        let url = URL(string: "https://notesapp-2d98c.firebaseio.com/Users/\(Auth.auth().currentUser!.uid).json?print=pretty")
        if let Url = url {
            let request = URLRequest(url: Url)
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let data = data, let currentKey = self.key {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                        for item in json {
                            userRef.child(item.key).child("Title").observeSingleEvent(of: .value, with: { (titleSnapshot) in
                                userRef.child(item.key).child("UpdateTime").observeSingleEvent(of: .value, with: { (updateTimeSnapshot) in
                                    userRef.child(item.key).child("NoteBody").observeSingleEvent(of: .value, with: { (messageSnapshot) in

                                            let decryptedTitle = decryptMessage(encryptedMessage: titleSnapshot.value as! String, encryptionKey: currentKey)
                                            let decryptedNote = decryptMessage(encryptedMessage: messageSnapshot.value as! String, encryptionKey: currentKey)
                                            let note = Note(stringID: item.key, title: decryptedTitle, updateTime: updateTimeSnapshot.value as! String, message: decryptedNote)
                                            self.notes.append(note)
                                            self.notesTable.reloadData()

                                    })

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
        let newNoteItem: Note = Note(stringID: String(arc4random()), title: "", updateTime: "", message: "")
        databaseRef.child(Auth.auth().currentUser!.uid).child(newNoteItem.stringID).child("Title").setValue("")
        databaseRef.child(Auth.auth().currentUser!.uid).child(newNoteItem.stringID).child("NoteBody").setValue("")
        databaseRef.child(Auth.auth().currentUser!.uid).child(newNoteItem.stringID).child("UpdateTime").setValue("")
        self.selectedNote = newNoteItem
        notes.append(newNoteItem)
         notesTable.reloadData()
        if let index = notes.firstIndex(where: { (item) -> Bool in
            item.stringID == newNoteItem.stringID
        }) {
            self.selectedCell = notesTable.cellForRow(at: [0,index])
        }
        self.performSegue(withIdentifier: "detailView", sender: self)

    }

    @IBAction func logoutButtonPressed(sender: Any?) {
        do {
            try Auth.auth().signOut()
            self.dismiss(animated: true, completion: nil)
        } catch {
            print("Error could not sign out")
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailView" {
            let nextView = segue.destination as! NoteDetailViewController
            nextView.priorView = self
            nextView.selectedCell = self.selectedCell
            if let currentNote = self.selectedNote, let currentKey = self.key {
                nextView.key = currentKey
                nextView.selectedNote = currentNote
                self.selectedNote = nil
                self.selectedCell = nil
            }
        }
    }

    func deleteCell(cellForNote: Note) {
        /*for item in notes {
            if item.title == (cell as! NoteCell).titleLabel.text! {
                let index = notes.lastIndex { (note) -> Bool in
                    note === item
                }
                notes.remove(at: index!)
                notesTable.deleteRows(at: [[0,index!]], with: UITableView.RowAnimation.bottom)
                table
            }
        }*/
        let index = notes.firstIndex { (currentNote) -> Bool in
            currentNote.stringID == cellForNote.stringID
        }
        notes.remove(at: index!)
        notesTable.deleteRows(at: [[0,index!]], with: UITableView.RowAnimation.bottom)
    }

    func updateCell(cell: UITableViewCell, oldNote: Note, newNote: Note) {
        let index = notes.firstIndex { (currentNote) -> Bool in
            currentNote.stringID == oldNote.stringID
        }
        notes[index!] = newNote
        let tableCell = notesTable.cellForRow(at: [0,index!]) as! NoteCell
        tableCell.titleLabel.text! = newNote.title
        tableCell.updateTimeLabel.text! = newNote.updateTime
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
        cell.updateTimeLabel.fadeTransition(1.0)
        cell.titleLabel.fadeTransition(1.0)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if notes.count == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        } else {
            self.selectedNote = notes[indexPath.row]
            self.selectedCell = tableView.cellForRow(at: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)
            self.performSegue(withIdentifier: "detailView", sender: self)
        }
    }
}
