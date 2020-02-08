//
//  SearchUISearchBar.swift
//  HandyMaps
//
//  Created by Jackson Lucas on 2/8/20.
//  Copyright © 2020 HandyMaps. All rights reserved.
//

import UIKit

class SearchUISearchBar: UISearchBar {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
