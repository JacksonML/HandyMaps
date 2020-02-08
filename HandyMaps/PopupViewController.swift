//
//  PopupViewController.swift
//  HandyMaps
//
//  Created by Jackson Lucas on 2/8/20.
//  Copyright © 2020 HandyMaps. All rights reserved.
//

import UIKit
import CoreLocation

class PopupViewController: UIViewController {

    @IBOutlet weak var directionsButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    var origin: CLLocation = .init()
    var destination: CLLocation = .init()
    var name: String = "Name"
    var parentViewViewController: ViewController?
    override func viewDidLoad() {
        super.viewDidLoad()
        directionsButton.layer.cornerRadius = 18
        // Do any additional setup after loading the view.
    }
    
    @IBAction func getDirections(_ sender: Any) {
        parentViewViewController?.fetchDirections(origin: origin, destination: destination)
        dismiss(animated: true, completion: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        nameLabel.text = name
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
