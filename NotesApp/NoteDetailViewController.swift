import Foundation
import UIKit
import Firebase
import FirebaseDatabase

class NoteDetailViewController: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet var titleLabel: UITextView!
    @IBOutlet var noteBody: UITextView!
    @IBOutlet var deleteButton: UIButton!
    var selectedNote: Note?
    weak var priorView: NotesListViewController?
    var selectedCell: UITableViewCell?
    let userRef = Database.database().reference(withPath: "Users").child(Auth.auth().currentUser!.uid)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noteBody.delegate = self

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
        userRef.child(selectedNote!.stringID).removeValue()
        performSegue(withIdentifier: "unwindToTable", sender: self)
        priorView?.deleteCell(cellForNote: self.selectedNote!)
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView === noteBody {
            userRef.child(selectedNote!.stringID).child("NoteBody").setValue(noteBody.text)
        } else if textView === titleLabel {
            userRef.child(selectedNote!.stringID).child("Title").setValue(titleLabel.text)
        }
        getUpdateTime()
    }

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

    func getUpdateTime() {
        var weekdayString: String?
        var monthString: String?
        var ampm: String?
        var convertedHour: Int?
        let date = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)

        if weekday == 1 {
            weekdayString = "Sunday"
        } else if weekday == 2 {
            weekdayString = "Monday"
        } else if weekday == 3 {
            weekdayString = "Tuesday"
        } else if weekday == 4 {
            weekdayString = "Wednesday"
        } else if weekday == 5 {
            weekdayString = "Thursday"
        } else if weekday == 6 {
            weekdayString = "Friday"
        } else if weekday == 7 {
            weekdayString = "Saturday"
        }

        if month == 1 {
            monthString = "January"
        } else if month == 2 {
            monthString = "February"
        } else if month == 3 {
            monthString = "March"
        } else if month == 4 {
            monthString = "April"
        } else if month == 5 {
            monthString = "May"
        } else if month == 6 {
            monthString = "June"
        } else if month == 7 {
            monthString = "July"
        } else if month == 8 {
            monthString = "August"
        } else if month == 9 {
            monthString = "September"
        } else if month == 10 {
            monthString = "October"
        } else if month == 11 {
            monthString = "November"
        } else if month == 12 {
            monthString = "December"
        }

        if hour < 12 {
            ampm = "AM"
        } else {
            ampm = "PM"
        }

        if hour == 13 {
            convertedHour = 1
        } else if hour == 14 {
            convertedHour = 2
        } else if hour == 15 {
            convertedHour = 3
        } else if hour == 16 {
            convertedHour = 4
        } else if hour == 17 {
            convertedHour = 5
        } else if hour == 18 {
            convertedHour = 6
        } else if hour == 19 {
            convertedHour = 7
        } else if hour == 20 {
            convertedHour = 8
        } else if hour == 21 {
            convertedHour = 9
        } else if hour == 22 {
            convertedHour = 10
        } else if hour == 23 {
            convertedHour = 11
        } else if hour == 0 {
            convertedHour = 12
        } else {
            convertedHour = hour
        }

        let day = calendar.component(.day, from: date)
        let minute = calendar.component(.minute, from: date)
        if let wds = weekdayString, let mstring = monthString, let hrs = convertedHour, let AmPm = ampm, let currentNote = self.selectedNote, let currentCell = self.selectedCell {
            let updateTimeMessage = "Updated \(wds), \(mstring) \(day) at \(hrs):\(minute) \(AmPm)"
            userRef.child(selectedNote!.stringID).child("UpdateTime").setValue(updateTimeMessage)
            self.priorView?.updateCell(cell: currentCell, oldNote: currentNote, newNote: Note(stringID: currentNote.stringID, title: self.titleLabel.text, updateTime: updateTimeMessage, message: self.noteBody.text))
        }
    }
}
