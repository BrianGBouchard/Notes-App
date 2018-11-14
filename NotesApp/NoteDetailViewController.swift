import Foundation
import UIKit
import Firebase
import FirebaseDatabase

class NoteDetailViewController: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet var titleLabel: UITextView!
    @IBOutlet var noteBody: UITextView!
    var selectedNoteId: String?
    let userRef = Database.database().reference(withPath: "Users").child(Auth.auth().currentUser!.uid)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noteBody.delegate = self

        userRef.child(selectedNoteId!).child("Title").observeSingleEvent(of: .value) { (snapshot) in
            self.titleLabel.text = snapshot.value as? String
            if self.titleLabel.text == "" {
                self.titleLabel.text = "[Add Title]"
            }
        }
        userRef.child(selectedNoteId!).child("NoteBody").observeSingleEvent(of: .value) { (snapshot) in
            self.noteBody.text = snapshot.value as? String
            if self.noteBody.text == "" {
                self.noteBody.text = "[Add Text]"
            }
        }

        /*let deselectTextView = UITapGestureRecognizer(target: self, action: #selector(handleDeselectTap(gesture:)))
        self.view.addGestureRecognizer(deselectTextView)

        let removeTitlePlaceholderText = UITapGestureRecognizer(target: self, action: #selector(handleRemoveTitlePlaceholderTap(gesture:)))
        titleLabel.addGestureRecognizer(removeTitlePlaceholderText)

        let removeBodyPlaceholderText = UITapGestureRecognizer(target: self, action: #selector(handleRemoveBodyPlaceholderTap(gesture:)))
        noteBody.addGestureRecognizer(removeBodyPlaceholderText)*/
    }

    @objc func handleDeselectTap(gesture: UITapGestureRecognizer) {
        if noteBody.isFirstResponder {
            noteBody.resignFirstResponder()
        } else if titleLabel.isFirstResponder {
            titleLabel.resignFirstResponder()
        }
    }

    @objc func handleRemoveTitlePlaceholderTap(gesture: UITapGestureRecognizer) {
        if titleLabel.text == "[Add Title]" {
            titleLabel.text = ""
        }
    }

    @objc func handleRemoveBodyPlaceholderTap(gesture: UITapGestureRecognizer) {
        if noteBody.text == "[Add Text]" {
            noteBody.text = ""
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        if textView === noteBody {
            userRef.child(selectedNoteId!).child("NoteBody").setValue(noteBody.text)
        } else if textView === titleLabel {
            userRef.child(selectedNoteId!).child("Title").setValue(titleLabel.text)
        }
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

}
