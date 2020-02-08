//
//  SearchBarViewController.swift
//  HandyMaps
//
//  Created by Jackson Lucas on 2/8/20.
//  Copyright © 2020 HandyMaps. All rights reserved.
//

import UIKit

class SearchBarViewController: UIViewController {

    @IBOutlet weak var innerView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        innerView.layer.cornerRadius = 10
        innerView.layer.masksToBounds = true
        // Do any additional setup after loading the view.
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
