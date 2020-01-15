//
//  AuthViewController.swift
//  TagCashier
//
//  Created by Eugene L. on 15/1/20.
//  Copyright © 2020 ARandomDeveloper. All rights reserved.
//

import UIKit
import Firebase

class AuthViewController: UIViewController {

    @IBOutlet weak var ContainerView: UIView!
    @IBOutlet weak var SignInHeader: UIView!
    @IBOutlet weak var EmailTextField: UITextField!
    @IBOutlet weak var PasswordTextField: UITextField!
    @IBOutlet weak var LoginContainer: UIView!
    @IBOutlet weak var SignupContainer: UIView!
    
    @IBOutlet weak var GradientView: UIView!
    @IBAction func tappedOut(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func pressedLogIn(_ sender: Any) {
        
        if let email = EmailTextField.text {
            if let password = PasswordTextField.text {
                Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
                    if error == nil {
                        // No error, proceed
                        Auth.auth().currentUser?.getIDTokenResult(completion: { (result, error) in
                            if let isCashier = result?.claims["cashier"] as? Bool {
                                if isCashier {
                                    self.dismiss(animated: true, completion: nil)
                                } else {
                                    self.presentSimpleAlert(title: "Invalid account", message: "Please sign in with your company cashier account. Thank you.", btnMsg: "Continue")
                                }
                            }
                        })
                    } else {
                        if let errorCode = error?._code {
                            if let authError = AuthErrorCode(rawValue: errorCode) {
                                self.handleAuthError(error: authError)
                            }
                        }
                    }
                }
            } else {
                // No password!
            }
        } else {
            // No email
        }
        
    }
    @IBAction func pressedSignUp(_ sender: Any) {
        if let email = EmailTextField.text {
            if let password = PasswordTextField.text {
                Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
                    if error == nil {
                        // No error, proceed
                        let alert = UIAlertController(title: "Sign up successful!", message: "Your account has been created and is ready for use! :D", preferredStyle: .alert)
                        alert.addAction(.init(title: "Let's go!", style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        if let errorCode = error?._code {
                            if let authError = AuthErrorCode(rawValue: errorCode) {
                                self.handleAuthError(error: authError)
                            }
                        }
                    }
                }
            } else {
                // No password!
            }
        } else {
            // No email
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UI Inits
        ContainerView.dropShadow(radius: 5, widthOffset: 0, heightOffset: 0)
        EmailTextField.dropShadow(radius: 3, widthOffset: 0, heightOffset: 0)
        PasswordTextField.dropShadow(radius: 3, widthOffset: 0, heightOffset: 0)
        LoginContainer.dropShadow(radius: 3, widthOffset: 0, heightOffset: 0)
        SignupContainer.dropShadow(radius: 3, widthOffset: 0, heightOffset: 0)
        
        SignInHeader.layer.cornerRadius = 10
        ContainerView.layer.cornerRadius = 10
        LoginContainer.layer.cornerRadius = 10
        SignupContainer.layer.cornerRadius = 10
        
        GradientView.addGradientBackground(firstColor: .systemGreen, secondColor: .white, width: Double(GradientView.bounds.width), height: Double(GradientView.bounds.height))

        // Do any additional setup after loading the view.
        
    }
    
    func handleAuthError(error: AuthErrorCode) {
        
        switch error {
            
        case .emailAlreadyInUse:
            self.presentSimpleAlert(title: "Email Not Available",
                                    message: "The email you tried to sign up with is already in use. Would you like to log in instead?",
                                    btnMsg: "Continue")
            
        case .invalidEmail:
            self.presentSimpleAlert(title: "Invalid Email",
                                    message: "The email you keyed in was not valid. It should follow the format xxx@xxx.xxx",
                                    btnMsg: "Continue")
            
        case .wrongPassword:
            self.presentSimpleAlert(title: "Wrong Password",
                                    message: "The password you keyed in was incorrect. Try again maybe?",
                                    btnMsg: "Continue")
            
        case .tooManyRequests:
            self.presentSimpleAlert(title: "Too Many Requests",
                                    message: "You keyed in your password incorrectly too many times. Try again in a moment.",
                                    btnMsg: "Continue")
            
        case .userNotFound:
            self.presentSimpleAlert(title: "User Not Found",
                                    message: "We couldn't find the email you tried to log in with. Would you like to sign up instead?",
                                    btnMsg: "Continue")
            
        case .networkError:
            self.presentSimpleAlert(title: "Network Error",
                                    message: "We can't communicate with our servers at the moment. :(",
                                    btnMsg: "Continue")
            
        case .weakPassword:
            self.presentSimpleAlert(title: "Password too weak",
                                    message: "Your password should be at least 6 characters long.",
                                    btnMsg: "Continue")
            
        default: return
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
