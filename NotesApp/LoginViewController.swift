import UIKit
import Firebase
import FirebaseAuth
import CoreData

class LoginViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {

    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var activityMonitor: UIActivityIndicatorView!
    @IBOutlet var loginButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        activityMonitor.hidesWhenStopped = true

        let backgroundTapped = UITapGestureRecognizer(target: self, action: #selector(closeKeyboardTap(sender:)))
        self.view.addGestureRecognizer(backgroundTapped)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        perform(#selector(loginButtonPressed(sender:)), with: loginButton)

        return true
    }

    @IBAction @objc func loginButtonPressed(sender: Any?) {
        if emailTextField.text != "" && passwordTextField.text != "" {
            activityMonitor.startAnimating()
            Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
                if user != nil {
                    self.performSegue(withIdentifier: "login", sender: self)
                    self.activityMonitor.stopAnimating()
                } else {
                    if let errorDescription = error?.localizedDescription {
                        let alert = UIAlertController(title: "Error", message: errorDescription, preferredStyle: .alert)
                        let okButton = UIAlertAction(title: "Ok", style: .default, handler: nil)
                        alert.addAction(okButton)
                        self.activityMonitor.stopAnimating()
                        self.present(alert, animated: true)
                    } else {
                        let alert = UIAlertController(title: "Error", message: nil, preferredStyle: .alert)
                        let okButton = UIAlertAction(title: "Ok", style: .default, handler: nil)
                        alert.addAction(okButton)
                        self.activityMonitor.stopAnimating()
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }

    @IBAction func signUpButtonPressed(sender: Any?) {
        if emailTextField.text != "" && passwordTextField.text != "" {
            activityMonitor.startAnimating()
            Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
                if user != nil {
                    self.perform(#selector(self.loginButtonPressed(sender:)), with: self.loginButton)
                } else {
                    if let errorDescription = error?.localizedDescription {
                        let alert = UIAlertController(title: "Error", message: errorDescription, preferredStyle: .alert)
                        let okButton = UIAlertAction(title: "Ok", style: .default, handler: nil)
                        alert.addAction(okButton)
                        self.activityMonitor.stopAnimating()
                        self.present(alert, animated: true)
                    } else {
                        let alert = UIAlertController(title: "Error", message: nil, preferredStyle: .alert)
                        let okButton = UIAlertAction(title: "Ok", style: .default, handler: nil)
                        alert.addAction(okButton)
                        self.activityMonitor.stopAnimating()
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "login" {
            let nextView = (segue.destination as! UINavigationController).viewControllers[0] as! NotesListViewController
            if let passwordText = passwordTextField.text {
                nextView.key = passwordText
                self.emailTextField.text = ""
                self.passwordTextField.text = ""
            }
        }
    }

    @objc func closeKeyboardTap(sender: Any?) {
        if emailTextField.isFirstResponder {
            emailTextField.resignFirstResponder()
        } else if passwordTextField.isFirstResponder {
            passwordTextField.resignFirstResponder()
        }
    }
}


