//
//  SettingsViewController.swift
//  WebimClientLibrary_Example
//
//  Created by Nikita Lazarev-Zubov on 28.11.17.
//  Copyright © 2017 Webim. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import PopupDialog
import UIKit

/**
 View controller that presents settings.
 - Author:
 Nikita Lazarev-Zubov
 - Copyright:
 2017 Webim
 */
class SettingsViewController: UIViewController {
    
    // MARK: - Constants
    private enum AlertDialog: String {
        case BUTTON_TITLE = "OK"
        case BUTTON_ACCESSIBILITY_HINT = "Closes dialog."
        
        case TITLE = "Invalid account settings"
        case WRONG_ACCOUNT_NAME_MESSAGE = "Account name can't be empty."
        case WRONG_LOCATION_MESSAGE = "Location can't be empty."
    }
    
    
    // MARK: - Properties
    // MARK: Outlets
    @IBOutlet weak var accountNameTextField: UITextField!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var pageTitleTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        accountNameTextField.text = Settings.shared.accountName
        locationTextField.text = Settings.shared.location
        pageTitleTextField.text = Settings.shared.pageTitle
        
        setupNavigationItem()
        
        setupSaveButton()
    }
    
    // MARK: Navigation
    override func shouldPerformSegue(withIdentifier identifier: String,
                                     sender: Any?) -> Bool {
        let accountName = accountNameTextField.text!
        let location = locationTextField.text!
        let pageTitle = pageTitleTextField.text!
        
        if accountName.isEmpty {
            showSettingsAlert(withMessage: AlertDialog.WRONG_ACCOUNT_NAME_MESSAGE.rawValue)
            
            return false
        }
        
        if location.isEmpty {
            showSettingsAlert(withMessage: AlertDialog.WRONG_LOCATION_MESSAGE.rawValue)
            
            return false
        }
        
        Settings.shared.accountName = accountName
        Settings.shared.location = location
        if !pageTitle.isEmpty {
            Settings.shared.pageTitle = pageTitle
        }
        
        return true
    }
    
    
    // MARK: Private methods
    
    /**
     Sets up navigation item.
     - returns:
     No return value.
     - Author:
     Nikita Lazarev-Zubov
     - Copyright:
     2017 Webim
     */
    private func setupNavigationItem() {
        let navigationItemImageView = UIImageView(image: #imageLiteral(resourceName: "LogoWebimNavigationBar"))
        navigationItemImageView.contentMode = .scaleAspectFit
        navigationItem.titleView = navigationItemImageView
    }
    
    /**
     Sets up Save button.
     - returns:
     No return value.
     - Author:
     Nikita Lazarev-Zubov
     - Copyright:
     2017 Webim
     */
    private func setupSaveButton() {
        saveButton.layer.cornerRadius = CORNER_RADIOUS
    }
    
    /**
     Shows popup alert view.
     Using PopupDialog.
     - parameter message:
     Message to show inside alert view.
     - returns:
     No return value.
     - Author:
     Nikita Lazarev-Zubov
     - Copyright:
     2017 Webim
     */
    private func showSettingsAlert(withMessage message: String) {
        let popup = PopupDialog(title: AlertDialog.TITLE.rawValue,
                                message: message)
        
        let okButton = CancelButton(title: AlertDialog.BUTTON_TITLE.rawValue,
                                    action: nil)
        okButton.accessibilityHint = AlertDialog.BUTTON_ACCESSIBILITY_HINT.rawValue
        popup.addButton(okButton)
        self.present(popup,
                     animated: true,
                     completion: nil)
    }
    
}