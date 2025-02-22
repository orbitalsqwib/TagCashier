//
//  CashierViewController.swift
//  TagCashier
//
//  Created by Eugene L. on 15/1/20.
//  Copyright © 2020 ARandomDeveloper. All rights reserved.
//

import UIKit
import CoreNFC
import Firebase

// Globals

// Variables
var receipts = [Receipt]()
var keyboardHeight:CGFloat = 0
var storeName = ""
var total:Double = 0
var receiptItems = [Receipt.ReceiptItem]()

// Constants
let ref = Database.database().reference()
let rowHeight = CGFloat(35)

class CashierViewController: UIViewController {
    
    @IBOutlet weak var Header: UIView!
    @IBOutlet weak var ReceiptCollectionView: UICollectionView!
    @IBOutlet weak var AddItemContainer: UIView!
    @IBOutlet weak var AddItemButton: UIButton!
    @IBOutlet weak var ProfileButtonContainer: UIView!
    @IBOutlet weak var ProfileButton: UIButton!
    @IBOutlet weak var ScanButtonContainer: UIView!
    @IBOutlet weak var ScanButton: UIButton!
    
    // Mark : IBActions
    
    @IBAction func clickedProfile(_ sender: Any) {
        //Show alert to sign out/rebind/bind card?
        
        //Get status of user
        if Auth.auth().currentUser != nil {
            
            // User currently logged in
            askUserToLogOut()
            
        } else {
            
            // No user logged in
            askUserToSignIn()
            
        }
    }
    
    @IBAction func clickedAddItem(_ sender: Any) {
        Auth.auth().currentUser?.getIDTokenResult(completion: { (result, error) in
            if let role = result?.claims["role"] as? String {
                if role == "cashier" {
                    self.presentAddMenu()
                } else {
                    self.presentSimpleAlert(title: "Invalid account", message: "Please sign in with your company cashier account. Thank you.", btnMsg: "Continue")
                }
            }
        })
    }
    
    @IBAction func clickedScan(_ sender: Any) {
        guard NFCNDEFReaderSession.readingAvailable else {
            let alertController = UIAlertController(
                title: "Scanning Not Supported",
                message: "This device doesn't support tag scanning.",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }

        let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session.alertMessage = "Looking for Tag card..."
        session.begin()
    }
    
    @IBAction func unwindAfterSigningIn(segue: UIStoryboardSegue) {
        if Auth.auth().currentUser == nil {
            self.performSegue(withIdentifier: "presentAuth", sender: self)
        } else {
            Auth.auth().currentUser?.getIDTokenResult(completion: { (result, error) in
                if let role:String = result?.claims["role"] as? String {
                    if role != "cashier" {
                        self.presentSimpleAlert(title: "Invalid credentials", message: "This terminal requires cashier access privileges", btnMsg: "Continue")
                        self.performSegue(withIdentifier: "presentAuth", sender: self)
                    }
                }
            })
        }
    }
    
    // Mark : View State Functions
    
    override func viewDidAppear(_ animated: Bool) {
        if Auth.auth().currentUser == nil {
            self.performSegue(withIdentifier: "presentAuth", sender: self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UI Init
        Header.dropShadow(radius: 5, widthOffset: 0, heightOffset: 1)
        ProfileButtonContainer.dropShadow(radius: 2, widthOffset: 1, heightOffset: 1)
        AddItemContainer.dropShadow(radius: 2, widthOffset: 1, heightOffset: 1)
        ScanButton.dropShadow(radius: 5, widthOffset: 0, heightOffset: 1)
        
        AddItemContainer.layer.cornerRadius = 24
        ProfileButtonContainer.layer.cornerRadius = 24
        ScanButtonContainer.layer.cornerRadius = 10
        
        // Other Init
        ReceiptCollectionView.dataSource = self
        ReceiptCollectionView.delegate = self
        reloadPreview()
        
    }
    
    func reloadPreview() {
        receipts.removeAll()
        var totalPrice:Double = 0
        for item in receiptItems {
            totalPrice += item.ItemSubTotal
        }
        totalPrice = round(total*100)/100
        total = totalPrice
        receipts.append(Receipt(StoreName: storeName, GrandTotal: total, Items: receiptItems))
        ReceiptCollectionView.reloadData()
    }
    
    func presentAddMenu() {
        //TODO: Insert Item Add
        let actionSheet = UIAlertController(title: "Manual Edit", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(.init(title: "Edit Store Name", style: .default, handler: { (result) in
            let alert = UIAlertController(title: "Edit Store Name", message: nil, preferredStyle: .alert)
            alert.addTextField { (textfield) in
                textfield.placeholder = "Enter new store name... "
            }
            alert.addAction(.init(title: "Save", style: .default, handler: { (result) in
                if let textField = alert.textFields?[0] {
                    storeName = textField.text ?? ""
                    self.reloadPreview()
                }
            }))
            alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }))
        actionSheet.addAction(.init(title: "Add Item", style: .default, handler: { (result) in
            let alert = UIAlertController(title: "Add Item", message: nil, preferredStyle: .alert)
            alert.addTextField { (textfield) in
                textfield.placeholder = "Enter item name... "
            }
            alert.addTextField { (textfield) in
                textfield.placeholder = "Enter item price... "
                textfield.keyboardType = .decimalPad
            }
            alert.addTextField { (textfield) in
                textfield.placeholder = "Enter item quantity... "
                textfield.keyboardType = .numberPad
            }
            alert.addAction(.init(title: "Save", style: .default, handler: { (result) in
                if let textFields = alert.textFields {
                    guard let newItemName = textFields[0].text else {
                        return
                    }
                    guard let newItemPrice = Double(textFields[1].text!) else {
                        return
                    }
                    let newItemPriceRounded = round(newItemPrice*100)/100
                    guard let newItemQty = Int(textFields[2].text!) else {
                        return
                    }
                    let subTotal = round(newItemPriceRounded * Double(newItemQty) * 100)/100
                    total += subTotal
                    receiptItems.append(Receipt.ReceiptItem(Name: newItemName, Qty: newItemQty, SubTotal: subTotal))
                    self.reloadPreview()
                }
            }))
            alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }))
        actionSheet.addAction(.init(title: "Reset Receipt", style: .destructive, handler: { (result) in
            storeName = ""
            receiptItems = [Receipt.ReceiptItem]()
            self.reloadPreview()
        }))
        actionSheet.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    // Mark : Auth Functions
    
    func askUserToSignIn() {
        
        let alert = UIAlertController(title: "Not Signed In", message: "Please sign in to enable cashier privileges", preferredStyle: .alert)
        alert.addAction(.init(title: "Continue", style: .cancel, handler: { (alert) in
            self.ReceiptCollectionView.refreshControl?.endRefreshing()
            self.performSegue(withIdentifier: "presentAuth", sender: self)
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func askUserToLogOut() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (result) in
            
            // Sign out
            self.signOut()
            self.performSegue(withIdentifier: "presentAuth", sender: self)
            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}

// Mark : Cell Classes

class ReceiptCollectionViewCell: UICollectionViewCell {
    
    var receiptItems = [Receipt.ReceiptItem]()
    @IBOutlet weak var ContainerView: UIView!
    @IBOutlet weak var ReceiptItemTableView: UITableView!
    @IBOutlet weak var StoreNameLabel: UILabel!
    @IBOutlet weak var TotalPriceLabel: UILabel!
    
}

class ReceiptItemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var ItemNameLabel: UILabel!
    @IBOutlet weak var ItemQtyLabel: UILabel!
    @IBOutlet weak var ItemPriceLabel: UILabel!
    
}

// Mark : CashierViewController Extensions

extension CashierViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return receipts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = ReceiptCollectionView.dequeueReusableCell(withReuseIdentifier: "receiptCell", for: indexPath) as! ReceiptCollectionViewCell
        
        var dataSource = [Receipt]()
        dataSource = receipts
        
        cell.ContainerView.layer.cornerRadius = 10
        cell.ContainerView.clipsToBounds = true
        cell.contentView.dropShadow(radius: 5, widthOffset: 1, heightOffset: 1)
        
        cell.StoreNameLabel.text = dataSource[indexPath.item].ReceiptStoreName
        cell.TotalPriceLabel.text = "$" + String(dataSource[indexPath.item].ReceiptTotal)
        cell.ReceiptItemTableView.delegate = cell
        cell.ReceiptItemTableView.dataSource = cell
        cell.receiptItems = dataSource[indexPath.item].ReceiptItems
        cell.ReceiptItemTableView.reloadData()
        
        return cell
    }
    
    
}

extension CashierViewController: UICollectionViewDelegate {
    
}

extension CashierViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = (self.view.window?.frame.width ?? UIScreen.main.bounds.width) - 10
        
        let numberOfItems = receipts[indexPath.item].ReceiptItems.count
        
        let height = CGFloat(numberOfItems) * (rowHeight) + (86 + 86)
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 5, left: 5, bottom: 80, right: 5)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
}

extension ReceiptCollectionViewCell: UITableViewDelegate {
    
}

extension ReceiptCollectionViewCell: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return receiptItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = ReceiptItemTableView.dequeueReusableCell(withIdentifier: "receiptItemCell", for: indexPath) as! ReceiptItemTableViewCell
        let item = receiptItems[indexPath.item]
        
        cell.ItemNameLabel.text = item.ItemName
        cell.ItemQtyLabel.text = String(format: "x%.d", item.ItemQty)
        cell.ItemPriceLabel.text = String(format: "$%.2f", item.ItemSubTotal)
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return rowHeight
        
    }
    
}

extension CashierViewController: NFCNDEFReaderSessionDelegate {
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            // Restart polling in 500 milliseconds.
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "More than 1 tag is detected. Please remove all tags and try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
        
        func readTag(tag: NFCNDEFTag) {
            tag.readNDEF(completionHandler: { (message: NFCNDEFMessage?, error: Error?) in
                var statusMessage: String
                if nil != error || nil == message {
                    statusMessage = "rip in error pls try again."
                } else {
                    statusMessage = "Card Detected! Working..."
                    DispatchQueue.main.async {
                        // Process detected NFCNDEFMessage objects.
                        if message != nil {
                            let records = message!.records
                            
                            guard let receiptData = records.first?.payload else {
                                self.presentSimpleAlert(title: "Invalid card", message: "This card doesn't seem to be a Tag Membership Card! Try again?", btnMsg: "Continue")
                                return
                            }
                            
                            // Should give me UID of user stored on card
                            let uid = String(String(decoding: receiptData, as: UTF8.self).dropFirst(1))
                            if uid != "" {
                                Auth.auth().currentUser?.getIDTokenResult(completion: { (result, error) in
                                    guard let cashierUID = Auth.auth().currentUser?.uid else {
                                        self.presentSimpleAlert(title: "Not signed in?", message: "you find yourself in a mysterious space because you should be signed in but we don't detect that? ._. ... impossible...", btnMsg: "nani?!")
                                        return
                                    }
                                    guard let companyID:String = result?.claims["company"] as? String else {
                                        return
                                    }
                                    let path = "companies/"+companyID+"/cashiers/"+cashierUID+"/receipts"
                                    let receiptRef = ref.child(path).childByAutoId()
                                    receiptRef.updateChildValues(["store": storeName])
                                    receiptRef.updateChildValues(["total": total])
                                    for item in receiptItems {
                                        let itemRef = receiptRef.child("items").childByAutoId()
                                        itemRef.updateChildValues(["name" : item.ItemName])
                                        itemRef.updateChildValues(["quantity" : item.ItemQty])
                                        itemRef.updateChildValues(["price" : item.ItemSubTotal])
                                    }
                                    if error != nil {
                                        return
                                    }
                                })
                                ref.child("cards/"+uid).observeSingleEvent(of: .value) { (snapshot) in
                                    guard let userID = snapshot.value as? String else {
                                        print("no matching user")
                                        return
                                    }
                                    
                                    let receiptRef = ref.child("users/"+userID+"/receipts").childByAutoId()
                                    receiptRef.updateChildValues(["store": storeName])
                                    receiptRef.updateChildValues(["total": total])
                                    for item in receiptItems {
                                        let itemRef = receiptRef.child("items").childByAutoId()
                                        itemRef.updateChildValues(["name" : item.ItemName])
                                        itemRef.updateChildValues(["quantity" : item.ItemQty])
                                        itemRef.updateChildValues(["price" : item.ItemSubTotal])
                                    }
                                }
                            }
                        }
                    }
                }
                
                session.alertMessage = statusMessage
                session.invalidate()
            })
        }
        
        // Connect to the found tag and write an NDEF message to it.
        let tag = tags.first!
        session.connect(to: tag, completionHandler: { (error: Error?) in
            if nil != error {
                session.alertMessage = "Unable to connect to tag."
                session.invalidate()
                return
            }
            
            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                guard error == nil else {
                    session.alertMessage = "Unable to query the NDEF status of tag."
                    session.invalidate()
                    return
                }

                switch ndefStatus {
                case .notSupported:
                    session.alertMessage = "Tag is not NDEF compliant."
                    session.invalidate()
                    
                case .readOnly:
                    session.alertMessage = "Tag is read only."
                    readTag(tag: tag)
                    
                case .readWrite:
                    session.alertMessage = "Reading Reciept..."
                    readTag(tag: tag)
                    
                @unknown default:
                    session.alertMessage = "Unknown NDEF tag status."
                    session.invalidate()
                }
            })
        })
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Check the invalidation reason from the returned error.
        if let readerError = error as? NFCReaderError {
            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                let alertController = UIAlertController(
                    title: "Session Invalidated",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
}
