import Foundation
import UIKit
import Firebase
import FirebaseDatabase
import RNCryptor

class NoteDetailViewController: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate {

    // MARK: Properties

    @IBOutlet var titleLabel: UITextView!
    @IBOutlet var noteBody: UITextView!
    @IBOutlet var deleteButton: UIButton!
    var selectedNote: Note?
    weak var priorView: NotesListViewController?
    var selectedCell: UITableViewCell?
    var key: String?
    let userRef = Database.database().reference(withPath: "Users").child(Auth.auth().currentUser!.uid)

    // MARK: View Controller Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noteBody.delegate = self

        // Creates placeholder text for "Title" and "Note Body" fields if they are empty
        if selectedNote?.title == "" {
            titleLabel.text = "[Add Title]"
        } else {
            titleLabel.text = selectedNote?.title
        }

        if selectedNote?.message == "" {
            noteBody.text = "[Add Text]"
        } else {
            noteBody.text = selectedNote?.message
        }

        deleteButton.layer.borderWidth = 1.0
        deleteButton.layer.borderColor = deleteButton.titleColor(for: .normal)?.cgColor
        deleteButton.layer.cornerRadius = 5.0
        deleteButton.clipsToBounds = true

        let deselectTextView = UITapGestureRecognizer(target: self, action: #selector(handleDeselectTap(gesture:)))
        self.view.addGestureRecognizer(deselectTextView)

        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(gesture:)))
        swipeGesture.direction = .right
        self.view.addGestureRecognizer(swipeGesture)
    }

    // If the title and message body are empty when the user exits this view, the selected note is removed from the database and local table data source
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if let priorView = self.priorView, let currentNote = self.selectedNote {
            if ((self.titleLabel.text == "[Add Title]" || self.titleLabel.text == "") && (self.noteBody.text == "[Add Text]" || self.noteBody.text == "")) {
                priorView.deleteCell(cellForNote: currentNote)
                userRef.child(currentNote.stringID).removeValue()
            }
            priorView.notesTable.reloadData()
        }
    }

    // MARK: Actions

    @objc func handleDeselectTap(gesture: UITapGestureRecognizer) {
        if noteBody.isFirstResponder {
            noteBody.resignFirstResponder()
        } else if titleLabel.isFirstResponder {
            titleLabel.resignFirstResponder()
        }
    }

    @objc func handleSwipe(gesture: UISwipeGestureRecognizer) {
        performSegue(withIdentifier: "unwindToTable", sender: self)
    }

    @IBAction func deleteButtonPressed(sender: Any?) {
        if let currentNote = self.selectedNote {
            userRef.child(selectedNote!.stringID).removeValue()
            if let priorView = self.priorView {
                if let index = priorView.notes.firstIndex(where: { (note) -> Bool in
                    currentNote.stringID == note.stringID }) {
                    priorView.notes.remove(at: index)
                }
            }

        performSegue(withIdentifier: "unwindToTable", sender: self)
        }
    }

    // MARK: Delegate Methods

    // Updates database and local table data source when information in a note is changed
    func textViewDidChange(_ textView: UITextView) {
        if let currentKey = self.key {
            do {
                // Encrypts input using the user's password as the encryption key
                let encryptedTitle = encryptMessage(message: self.titleLabel.text, encryptionKey: currentKey)
                let encryptedMessage = encryptMessage(message: self.noteBody.text, encryptionKey: currentKey)
                if textView === noteBody {
                    userRef.child(selectedNote!.stringID).child("NoteBody").setValue(encryptedMessage)
                } else if textView === titleLabel {
                    userRef.child(selectedNote!.stringID).child("Title").setValue(encryptedTitle)
                }
                // Updates
                getUpdateTime()
            }
        }

        if textView === noteBody && noteBody.text == "" {
            userRef.child(selectedNote!.stringID).child("NoteBody").setValue("")
        }

        if textView === titleLabel && titleLabel.text == "" {
            userRef.child(selectedNote!.stringID).child("Title").setValue("")
        }
    }

    // Removes placeholder text when user begins editing title or note
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView === titleLabel {
            if titleLabel.text == "[Add Title]" {
                titleLabel.text = ""
            }
        } else if textView === noteBody {
            if noteBody.text == "[Add Text]" {
                noteBody.text = ""
            }
        }
    }

    // Adds placeholder if the title or note body is empty when the user ends editing
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView === noteBody {
            if noteBody.text == "" {
                noteBody.text = "[Add Text]"
            }
        } else if textView === titleLabel {
            if titleLabel.text == "" {
                titleLabel.text = "[Add Title]"
            }
        }
    }

    // MARK: Update Data

    func getUpdateTime() {

        let currentDate = Date()

        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss +zzzz"

        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "'Last updated' MMM dd,yyyy 'at' K:mm a, z"

        // Converts current data and time to a readable format, updates cloud database and local table view data source
        if let date = dateFormatterGet.date(from: currentDate.description), let currentNote = self.selectedNote {
            let dateString = dateFormatterPrint.string(from: date)
            userRef.child(selectedNote!.stringID).child("UpdateTime").setValue(dateString)
            userRef.child(selectedNote!.stringID).child("Unix").setValue(currentDate.timeIntervalSince1970)
            if let currentCell = self.selectedCell {
                self.priorView?.updateCell(cell: currentCell, oldNote: currentNote, newNote: Note(stringID: currentNote.stringID, title: self.titleLabel.text, updateTime: dateString, message: self.noteBody.text, unix: currentDate.timeIntervalSince1970))
            }

            if let index = self.priorView?.notes.firstIndex(where: { (note) -> Bool in
                note.stringID == currentNote.stringID }) {
                self.priorView?.notes[index].message = self.noteBody.text
                self.priorView?.notes[index].title = self.titleLabel.text
                self.priorView?.notes[index].updateTime = dateString
                self.priorView?.notes.sort(by: { (note1, note2) -> Bool in
                    note1.unix > note2.unix
                })
            }

        } else {
            print("There was an error decoding the string")
        }

    }
}
