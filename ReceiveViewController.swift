//
//  ReceiveViewController.swift
//  MapTest
//
//  Created by 持田侑菜 on 2020/08/17.
//  Copyright © 2020 持田侑菜. All rights reserved.
//

import UIKit

class ReceiveViewController: UIViewController, UITextFieldDelegate {
    
    var address: String = ""
    @IBOutlet weak var textField: UITextField!
    
    @IBAction func closeButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        textField.delegate = self
        
        textField.text = address
    }
    
}
