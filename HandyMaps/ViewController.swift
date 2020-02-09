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

struct accessibleSpots: Decodable{
    let data: [[String]]
}

struct trashSpots: Decodable{
    let data: [[String]]
}

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
    var accessibleMarkerSpots: accessibleSpots?
    var trashMarkerSpots: trashSpots?
    var handicapMarkers: [GMSMarker] = [GMSMarker]()
    var trashMarkers: [GMSMarker] = [GMSMarker]()
    
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
        
        // Import Accessible spots as markers
        var filePath = Bundle.main.path(forResource: "handicapspots", ofType: "json")
        var contentData = FileManager.default.contents(atPath: filePath!)
        do {
            let parsedJSON = try JSONDecoder().decode(accessibleSpots.self, from: contentData!)
            accessibleMarkerSpots = parsedJSON
            
            createMarkers()
        } catch let jsonErr {
            print(jsonErr)
        }
        
         filePath = Bundle.main.path(forResource: "trashspots", ofType: "json")
        contentData = FileManager.default.contents(atPath: filePath!)

         do {
             let parsedJSON = try JSONDecoder().decode(trashSpots.self, from: contentData!)
             trashMarkerSpots = parsedJSON
             createMarkersTrash()
         } catch let jsonErr {
             print(jsonErr)
         }
        
        // Creates a marker in the center of the map.
        /*let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 33.9480, longitude: -83.3773)
        marker.title = "UGA"
        marker.snippet = "University of Georgia"
        marker.map = mapViewMap*/
        mapViewMap.isMyLocationEnabled = true
        mapViewMap.animate(toLocation: CLLocationCoordinate2D(latitude: (userLocation?.location?.coordinate.latitude)!, longitude: (userLocation?.location?.coordinate.longitude)!))
        mapViewMap.settings.myLocationButton = true
    }
    
    private func createMarkers() {
        for spot in accessibleMarkerSpots!.data {
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: CLLocationDegrees(Double(spot[2])!), longitude: CLLocationDegrees(Double(spot[3])!))
            marker.title = spot[0]
            marker.icon = UIImage(contentsOfFile: Bundle.main.path(forResource: "blue_MarkerH", ofType: "png")!)
            marker.map = mapViewMap
            handicapMarkers.append(marker)
        }
    }
    
    private func createMarkersTrash(){
        for spot in trashMarkerSpots!.data{
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: CLLocationDegrees(Double(spot[0])!), longitude:  CLLocationDegrees(Double(spot[1])!))
            marker.title = ""
            marker.icon = UIImage(contentsOfFile: Bundle.main.path(forResource: "green_MarkerT", ofType: "png")!)
                marker.map = mapViewMap
                trashMarkers.append(marker)
        }
    }
    
    @IBAction func handicapToggle(_ sender: UISwitch) {
        for marker in handicapMarkers {
            marker.map = sender.isOn ? mapViewMap : nil
        }
    }
    
    @IBAction func trashToggle(_ sender: UISwitch) {
        for marker in trashMarkers{
            marker.map = sender.isOn ? mapViewMap : nil
        }
    }
    private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        
        let geocoder = GMSGeocoder()
        
        geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
            guard let address = response?.firstResult(), let lines = address.lines else {
                return
            }
            
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // Declare GMSMarker instance at the class level.
    let infoMarker = GMSMarker()
    let placesClient: GMSPlacesClient = GMSPlacesClient()
    var walkingPath: GMSPolyline = GMSPolyline.init()
    
    // Attach an info window to the POI using the GMSMarker.
    func mapView(_ mapView: GMSMapView, didTapPOIWithPlaceID placeID: String,
                 name: String, location: CLLocationCoordinate2D) {
        
        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) |
            UInt(GMSPlaceField.placeID.rawValue) | UInt(GMSPlaceField.types.rawValue) | UInt(GMSPlaceField.coordinate.rawValue))!
        
        placesClient.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil, callback: {
            (place: GMSPlace?, error: Error?) in
            if let error = error {
                print("An error occurred: \(error.localizedDescription)")
                return
            }
            if let place = place {
                self.segueHelper(place: place, placeID: nil)
                
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
    
    func segueHelper(place: GMSPlace, placeID: String?) {
        var destinationCoordinate: CLLocation?
        for object in self.accessibleMarkerSpots!.data {
            if let placeId = placeID {
            if (placeId == object[1]) {
                destinationCoordinate = CLLocation(latitude: CLLocationDegrees(Double(object[2])!), longitude: CLLocationDegrees(Double(object[3])!))
                break
            } else {
                destinationCoordinate = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            }
            } else {
            if (place.placeID == object[1]) {
                destinationCoordinate = CLLocation(latitude: CLLocationDegrees(Double(object[2])!), longitude: CLLocationDegrees(Double(object[3])!))
                break
            } else {
                destinationCoordinate = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
            }
            }
        }
        self.performSegue(withIdentifier: "popupDirections", sender: nil)
        self.popupViewController?.name = place.name!
        self.popupViewController?.origin = (self.userLocation?.location!)!
        self.popupViewController?.destination = destinationCoordinate!
        self.popupViewController?.parentViewViewController = self
        self.destination = destinationCoordinate!
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
                        self.segueHelper(place: place, placeID: firstResult.placeID)
                        //self.fetchDirections(origin: (self.userLocation?.location)!, destination: destinationCoordinate)
                    }
                    
                })
                
            }
        })
        searchBar.endEditing(true)
    }

    func fetchDirections(origin: CLLocation, destination: CLLocation){
        self.walkingPath.map = nil
        let originCoords = String(origin.coordinate.latitude) + "," + String(origin.coordinate.longitude)
        let destinationCoords = String(destination.coordinate.latitude) + "," + String(destination.coordinate.longitude)
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=" + originCoords + "&destination=" + destinationCoords + "&mode=walking&key=INSERT_KEY_HERE"
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
                    if (routesArray != nil) {
                    DispatchQueue.main.async {
                        let path = GMSPath.init(fromEncodedPath: routesArray!)
                        self.walkingPath = GMSPolyline.init(path: path)
                    
                        self.walkingPath.strokeWidth = 6.0
                        self.walkingPath.strokeColor = .blue
                        self.walkingPath.map = self.mapViewMap
                    }
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
