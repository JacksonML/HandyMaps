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
import Network
import CFNetwork

class ViewController: UIViewController, CLLocationManagerDelegate, UISearchBarDelegate {
    
    
    var searchViewController: SearchViewController?
    var popupViewController :  PopupViewController?
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "searchBar" {
            
            if let vc = segue.destination as? SearchViewController {
                searchViewController = vc
            }
        } else if segue.identifier == "popupDirections" {
            if let vc = segue.destination as? PopupViewController {
                popupViewController = vc
            }
        }
    }
    
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
        
        searchViewController?.innerBar.delegate = self
        
        let camera = GMSCameraPosition.camera(withLatitude: 33.9475, longitude: -83.375, zoom: 15.0)
        mapViewMap.layoutIfNeeded()
        mapViewMap.camera = camera
        
        // Creates a marker in the center of the map.
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 33.9480, longitude: -83.3773)
        marker.title = "UGA"
        marker.snippet = "University of Georgia"
        marker.map = mapViewMap
        mapViewMap.isMyLocationEnabled = true
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
                print("The selected place is: \(String(describing: place.name)) with placeID: \(String(describing: place.placeID))")
            }
        })
        
        infoMarker.position = location
        infoMarker.title = name
        infoMarker.opacity = 0;
        infoMarker.infoWindowAnchor.y = 1
        infoMarker.map = mapView
        mapView.selectedMarker = infoMarker
    }
    
    var destination: CLLocation = .init()
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let client: GMSPlacesClient = GMSPlacesClient()
        client.autocompleteQuery(searchBar.text!, bounds: .none, filter: .none, callback: {
            (results, error) -> Void in
            guard error == nil else {
                print("Autocomplete error \(error)")
                return
            }
            if let results = results {
                let firstResult = results[0]
                searchBar.text = firstResult.attributedPrimaryText.string
                let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.coordinate.rawValue) | UInt(GMSPlaceField.name.rawValue))!
                self.placesClient.fetchPlace(fromPlaceID: firstResult.placeID, placeFields: fields, sessionToken: nil, callback: {
                    (place: GMSPlace?, error: Error?) in
                    if let error = error {
                        print("An error occurred: \(error.localizedDescription)")
                        return
                    }
                    if let place = place {
                        print("The selected place is: \(place.name)")
                        var destinationCoordinate = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
                        self.performSegue(withIdentifier: "popupDirections", sender: nil)
                        self.popupViewController?.name = place.name!
                        self.popupViewController?.origin = (self.userLocation?.location!)!
                        self.popupViewController?.destination = destinationCoordinate
                        self.popupViewController?.parentViewViewController = self
                        self.destination = destinationCoordinate
                        //self.fetchDirections(origin: (self.userLocation?.location)!, destination: destinationCoordinate)
                    }
                    
                })
                
            }
        })
        searchBar.endEditing(true)
        
    }
    
    func fetchDirections(origin: CLLocation, destination: CLLocation){
        let originCoords = String(origin.coordinate.latitude) + "," + String(origin.coordinate.longitude)
        let destinationCoords = String(destination.coordinate.latitude) + "," + String(destination.coordinate.longitude)
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=" + originCoords + "&destination=" + destinationCoords + "&mode=walking&key=ENTER_KEY_HERE"
        let url = NSURL(string: urlString)
        
        let task = URLSession.shared.dataTask(with: url! as URL) { (data, response, error) -> Void in
            
            do {
                if data != nil {
                    let dic = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableLeaves) as!  [String:AnyObject]
                    //                                print(dic)
                    
                    let status = dic["status"] as! String
                    var routesArray:String!
                    if status == "OK" {
                        routesArray = (((dic["routes"]!as! [Any])[0] as! [String:Any])["overview_polyline"] as! [String:Any])["points"] as! String
                    }
                    
                    DispatchQueue.main.async {
                        let path = GMSPath.init(fromEncodedPath: routesArray!)
                        let singleLine = GMSPolyline.init(path: path)
                        singleLine.strokeWidth = 6.0
                        singleLine.strokeColor = .blue
                        singleLine.map = self.mapViewMap
                    }
                    
                }
            } catch {
                print("Error")
            }
        }
        
        task.resume()
    }
}

extension ViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        //        reverseGeocodeCoordinate(position.target)
    }
}

extension ViewController: UIPopoverPresentationControllerDelegate {
    
    func popoverPresentationControllerDidDismissPopover() {
        print("GO BACL")
        
        fetchDirections(origin: (self.userLocation?.location!)!, destination: destination)
    }
}
