//
//  ViewController.swift
//  HandyMaps
//
//  Created by Jackson Lucas on 2/7/20.
//  Copyright © 2020 HandyMaps. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapViewMap: GMSMapView!
    var userLocation: CLLocationManager?
    @IBOutlet weak var searchBar: UIView!
    let containerView = UIView()
    override func viewDidLoad() {
        super.viewDidLoad()

        containerView.layer.borderColor = UIColor.black.cgColor
        searchBar.layer.shadowRadius = 3
        searchBar.layer.shadowOffset = CGSize(width: 0, height: 2)
        searchBar.layer.shadowOpacity = 0.6
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        userLocation = CLLocationManager()
        userLocation?.delegate = self
        userLocation?.requestWhenInUseAuthorization()
        searchBar.addSubview(containerView)
        mapViewMap.delegate = self
        
        let camera = GMSCameraPosition.camera(withLatitude: 33.9475, longitude: -83.375, zoom: 15.0)
        mapViewMap.layoutIfNeeded()
        mapViewMap.camera = camera
        
        // Creates a marker in the center of the map.
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 33.9480, longitude: -83.3773)
        marker.title = "UGA"
        marker.snippet = "University of Georgia"
        marker.map = mapViewMap
        mapViewMap.isMyLocationEnabled = true;
        mapViewMap.animate(toLocation: CLLocationCoordinate2D(latitude: (userLocation?.location?.coordinate.latitude)!, longitude: (userLocation?.location?.coordinate.longitude)!))
        mapViewMap.settings.myLocationButton = true
    }
    @IBOutlet weak var addressLabel: UILabel!
    private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        
      // 1
      let geocoder = GMSGeocoder()
        
      // 2
      geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
        guard let address = response?.firstResult(), let lines = address.lines else {
          return
        }
          
        // 3
        self.addressLabel.text = lines.joined(separator: "\n")
          
        // 4
        UIView.animate(withDuration: 0.25) {
          self.view.layoutIfNeeded()
        }
      }
    }
    
    // Declare GMSMarker instance at the class level.
    let infoMarker = GMSMarker()
    let placesClient: GMSPlacesClient = GMSPlacesClient()

    // Attach an info window to the POI using the GMSMarker.
    func mapView(_ mapView: GMSMapView, didTapPOIWithPlaceID placeID: String,
                 name: String, location: CLLocationCoordinate2D) {
        
        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) |
            UInt(GMSPlaceField.placeID.rawValue) | UInt(GMSPlaceField.types.rawValue))!
        
        placesClient.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil, callback: {
          (place: GMSPlace?, error: Error?) in
          if let error = error {
            print("An error occurred: \(error.localizedDescription)")
            return
          }
          if let place = place {
            
            if let types = place.types {
                self.infoMarker.snippet = types[0]
            }
            print("The selected place is: \(place.name)")
          }
        })
        
      infoMarker.position = location
      infoMarker.title = name
      infoMarker.opacity = 0;
      infoMarker.infoWindowAnchor.y = 1
      infoMarker.map = mapView
      mapView.selectedMarker = infoMarker
    }
    
}

extension ViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
      reverseGeocodeCoordinate(position.target)
    }
}
