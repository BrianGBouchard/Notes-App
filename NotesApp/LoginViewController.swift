import UIKit
import Firebase
import FirebaseAuth
import LUKeychainAccess

class LoginViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {

    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var activityMonitor: UIActivityIndicatorView!
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var checkmark: UIImageView!
    @IBOutlet var checkmarkSuperview: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        checkmark.isHidden = true
        emailTextField.delegate = self
        passwordTextField.delegate = self
        activityMonitor.hidesWhenStopped = true
        if let keychainEmail = LUKeychainAccess.standard().string(forKey: "email"), let keychainPassword = LUKeychainAccess.standard().string(forKey: "password") {
            emailTextField.text = keychainEmail
            passwordTextField.text = keychainPassword
            perform(#selector(loginButtonPressed(sender:)), with: loginButton)
        }

        let backgroundTapped = UITapGestureRecognizer(target: self, action: #selector(closeKeyboardTap(sender:)))
        self.view.addGestureRecognizer(backgroundTapped)

        let selectKeepMeLoggedIn = UITapGestureRecognizer(target: self, action: #selector(keepMeLoggedInTapped(gesture:)))
        checkmarkSuperview.addGestureRecognizer(selectKeepMeLoggedIn)

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

    @objc func keepMeLoggedInTapped(gesture: UITapGestureRecognizer) {
        if checkmark.isHidden == false {
            checkmark.isHidden = true
        } else if checkmark.isHidden {
            checkmark.isHidden = false
        }
    }

    @IBAction @objc func loginButtonPressed(sender: Any?) {
        if emailTextField.text != "" && passwordTextField.text != "" {
            activityMonitor.startAnimating()
            Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
                if user != nil {
                    if self.checkmark.isHidden == false {
                        LUKeychainAccess.standard().setString(self.emailTextField.text!, forKey: "email")
                        LUKeychainAccess.standard().setString(self.passwordTextField.text!, forKey: "password")
                        self.checkmark.isHidden = true
                    }
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


