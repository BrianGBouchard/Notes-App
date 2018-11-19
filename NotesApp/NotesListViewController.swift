import Foundation
import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import RNCryptor

class NotesListViewController: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    // MARK: Properties

    @IBOutlet var notesTable: UITableView!
    @IBOutlet var logoutButton: UIButton!

    var notes: Array<Note> = []
    var notesIDs: Array<String> = []
    var selectedNote: Note?
    var selectedCell: UITableViewCell?
    var key: String?
    let databaseRef = Database.database().reference(withPath: "users")

    // MARK: View Controller Methods

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

    // MARK: Fetch database data

    // Locally instantiates "Note" objects using data from Firebase and adds them to the Table View data source "notes" array
    func getData() {
        let userRef = databaseRef.child(Auth.auth().currentUser!.uid)
        if let currentKey = self.key {
            userRef.child("Notes").observeSingleEvent(of: .value, with: { (childrenValues) in
                let itemValues = childrenValues.children.allObjects as! [DataSnapshot]
                for itemKeys in itemValues {
                    let item = itemKeys.key
                    userRef.child("Notes").child(item).child("Title").observeSingleEvent(of: .value, with: { (titleSnapshot) in
                        userRef.child("Notes").child(item).child("UpdateTime").observeSingleEvent(of: .value, with: { (updateTimeSnapshot) in
                            userRef.child("Notes").child(item).child("NoteBody").observeSingleEvent(of: .value, with: { (messageSnapshot) in
                                userRef.child("Notes").child(item).child("Unix").observeSingleEvent(of: .value, with: { (unixSnapshot) in
                                    let decryptedTitle = decryptMessage(encryptedMessage: titleSnapshot.value as! String, encryptionKey: currentKey)
                                    let decryptedNote = decryptMessage(encryptedMessage: messageSnapshot.value as! String, encryptionKey: currentKey)
                                    let note = Note(stringID: item, title: decryptedTitle, updateTime: updateTimeSnapshot.value as! String, message: decryptedNote, unix: unixSnapshot.value as! Double)
                                    self.notes.append(note)
                                    self.notesIDs.append(note.stringID)
                                    self.notes.sort(by: { (note1, note2) -> Bool in
                                        note1.unix > note2.unix
                                    })
                                    self.notesTable.reloadData()
                                })
                            })

                        })
                    })
                }
            })
        }

        // Alternate method for iterating through a database, using URLSession

        /*let url = URL(string: "https://notesapp-2d98c.firebaseio.com/users/\(Auth.auth().currentUser!.uid).json?print=pretty")
        if let Url = url {
            let request = URLRequest(url: Url)
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let data = data, let currentKey = self.key {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                        if let entries = json["Notes"] as? [(key: String, value: Any)] {
                            for item in entries  {
                                userRef.child(item.key).child("Title").observeSingleEvent(of: .value, with: { (titleSnapshot) in
                                    userRef.child(item.key).child("UpdateTime").observeSingleEvent(of: .value, with: { (updateTimeSnapshot) in
                                        userRef.child(item.key).child("NoteBody").observeSingleEvent(of: .value, with: { (messageSnapshot) in
                                            userRef.child(item.key).child("Unix").observeSingleEvent(of: .value, with: { (unixSnapshot) in
                                                let decryptedTitle = decryptMessage(encryptedMessage: titleSnapshot.value as! String, encryptionKey: currentKey)
                                                let decryptedNote = decryptMessage(encryptedMessage: messageSnapshot.value as! String, encryptionKey: currentKey)
                                                let note = Note(stringID: item.key, title: decryptedTitle, updateTime: updateTimeSnapshot.value as! String, message: decryptedNote, unix: unixSnapshot.value as! Double)
                                                self.notes.append(note)
                                                self.notes.sort(by: { (note1, note2) -> Bool in
                                                    note1.unix > note2.unix
                                                })
                                                self.notesTable.reloadData()
                                            })
                                        })

                                    })
                                })
                            }
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        task.resume()
        }
    */
    }

    // MARK: Actions

    @objc func handleLongPress(longPress: UILongPressGestureRecognizer) {
        if longPress.state == UIGestureRecognizer.State.began {

            for cell in notesTable.visibleCells {
                if cell.isHighlighted {
                    let highlightedCell = cell as! NoteCell
                    let alert = UIAlertController(title: "Delete Note?", message: nil, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "Delete", style: .default) { (action) in
                        self.databaseRef.child(Auth.auth().currentUser!.uid).child("Notes").child(highlightedCell.stringID!).removeValue()
                        let indexPath = self.notes.firstIndex(where: { (note) -> Bool in
                            note.stringID == highlightedCell.stringID!
                        })
                        if let index = indexPath {
                            self.notes.remove(at: index)
                            self.notesTable.deleteRows(at: [[0, index]], with: UITableView.RowAnimation.automatic)
                        }
                    }
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    alert.addAction(okAction)
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // Checks for duplicate IDs
    @IBAction func addButtonPressed(sender: Any?) {
        var newID = String(arc4random())
        if notesIDs.contains(newID) {
            while notesIDs.contains(newID) {
                newID = String(arc4random())
                if notesIDs.contains(newID) == false {
                    addNote(id: newID)
                }
            }
        } else {
            addNote(id: newID)
        }
    }

    func addNote(id: String) {
        let newNoteItem: Note = Note(stringID: id, title: "", updateTime: "", message: "", unix: Date().timeIntervalSince1970)
        databaseRef.child(Auth.auth().currentUser!.uid).child("Notes").child(newNoteItem.stringID).child("Title").setValue("")
        databaseRef.child(Auth.auth().currentUser!.uid).child("Notes").child(newNoteItem.stringID).child("NoteBody").setValue("")
        databaseRef.child(Auth.auth().currentUser!.uid).child("Notes").child(newNoteItem.stringID).child("UpdateTime").setValue("")
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
            self.key = nil
            self.dismiss(animated: true, completion: nil)
        } catch {
            print("Error could not sign out")
        }
    }

    @IBAction func unwindToTable(segue: UIStoryboardSegue) {
    }

    func deleteCell(cellForNote: Note) {
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


    // MARK: TableView delegate methods

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
        if cell.titleLabel.text! == "" || cell.titleLabel.text! == "[Add Title]" {
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
            self.selectedNote = notes[indexPath.row]
            self.selectedCell = tableView.cellForRow(at: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)
            self.performSegue(withIdentifier: "detailView", sender: self)
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let noteCell = cell as! NoteCell
        noteCell.titleLabel.fadeTransition(1.0)
        noteCell.updateTimeLabel.fadeTransition(1.0)
    }
}
