//
//  ISSSendAlert.swift
//  iss-passes
//
//  Created by Bradston S Henry on 1/16/18.
//  Copyright © 2018 Brad. All rights reserved.
//

import Foundation
import UIKit

//  Function to display error messages
//  Grabs the topmost view controller and displays the message as an alert
func sendAlert(message: String) {
    if var viewedController = UIApplication.shared.keyWindow?.rootViewController {
        while let pVC = viewedController.presentedViewController {
            viewedController = pVC
        }
        
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title:"Dismiss", style: UIAlertActionStyle.default, handler: nil))
        viewedController.present(alertController, animated: true, completion:nil)
    }
}
