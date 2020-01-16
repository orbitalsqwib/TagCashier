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
let ref = Database.database().reference()

// Variables
var receipts = [Receipt]()
var keyboardHeight:CGFloat = 0

// Constants
let rowHeight = CGFloat(33)

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
    }
    
    @IBAction func unwindAfterSigningIn(segue: UIStoryboardSegue) {
        if Auth.auth().currentUser == nil {
            self.performSegue(withIdentifier: "presentAuth", sender: self)
        } else {
            // TODO: set receipt title to store name
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
        
    }
    
    func presentAddMenu() {
        //TODO: Insert Item Add
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
