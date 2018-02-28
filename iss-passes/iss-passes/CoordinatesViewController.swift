//
//  ISSSendAlert.swift
//  iss-passes
//
//  Created by Bradston S Henry on 1/16/18.
//  Copyright © 2018 Brad. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class CoordinatesViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var issLocationButton: UIButton!
    @IBOutlet weak var showAllButton: UIButton!
    @IBAction func myLocationButtonAction(_ sender: Any) {
        FocusOnUserLocation()
    }
    @IBAction func issLocationButtonAction(_ sender: Any) {
        GetCurrentISSLocation(showAll: false)
        FocusOnISSLocation()
    }
    @IBAction func showAllButtonAction(_ sender: Any) {
        GetCurrentISSLocation(showAll: true)
        FocusOnBothLocations()
    }
    
    @IBOutlet weak var spaceStationImage: UIImageView!
    
    var locationManager: CLLocationManager!
    
    var currentUserLatitude : Double = 0.0
    var currentUserLongitude : Double = 0.0
    var issCurrentLatitude : Double = 0.0
    var issCurrentLongitude: Double = 00
    var userAnnotation = MKPointAnnotation()
    var issAnnotation = MKPointAnnotation()
    var userLocation = CLLocationCoordinate2D()
    var issLocation = CLLocationCoordinate2D()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup Location Manager to retrieve device GPS and request appriorpiate permissions
        locationManager = CLLocationManager()
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        //Ensure location services are enambled before performing specified tasks
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }else{
            sendAlert(message: "Location Services Not Enabled. Enable Location Services in Privacy Settings")
        }
        
        //Load Initial Location of ISS and show both user location and ISS in view
        GetCurrentISSLocation(showAll: true)
        
        //Rotates SpaceStation Image around Globe Button
        RotateImage(spaceStationImage, duration:2.5, direction:-1)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Using location manager, update map with users device location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        
        //Stop from continually getting device location
        manager.stopUpdatingLocation();
        //Call function to set location coordinates approriately
        SetLocationCoordinates(latitude,longitude)
        
    }
    
    //Catch error that may occur in Location Manager
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let nsError = error as NSError
        
        //If error code is 1, error is in reference to user disabling location services for application
        if(nsError.code == 1){
            sendAlert(message: "Location Services disabled for application. Enable Location services in Privacy Settings for application.")
        }else{
            sendAlert(message: "GPS error detected. Retry when service is avalaible")
        }
        
    }
    
    //Set the device location coordinates to corresponding variables
    func SetLocationCoordinates(_ lat: Double, _ lon: Double){
        currentUserLatitude = lat
        currentUserLongitude = lon
        SetUserLocationonMap(lat,lon)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        //Pass user device coordinates to next view controller for network call
        if let tableviewController = segue.destination as? ISSTableViewController{
            tableviewController.userLatitude = currentUserLatitude
            tableviewController.userLongitude = currentUserLongitude
        }
        
    }
    
    //Set The Location of user on map with annotation
    func SetUserLocationonMap(_ lat: Double, _ lon: Double){
        userLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        userAnnotation.coordinate = userLocation
        mapView.addAnnotation(userAnnotation)
        mapView.showAnnotations([userAnnotation], animated: true)
    }
    
    //Focus on user location on map
    func FocusOnUserLocation(){
        mapView.showAnnotations([userAnnotation], animated: true)
    }
    
    //Focus on ISS current location on map
    func FocusOnISSLocation(){
        mapView.showAnnotations([issAnnotation], animated: true)
    }
    
    //Focus on both user and ISS locations on map
    //TODO: Given more time, Would fix issue where markers may not be in view of map view when points are far from each other
    func FocusOnBothLocations(){
        mapView.showAnnotations([userAnnotation,issAnnotation], animated: true)
    }
    
    //Animates an image repeatedly rotating for a specified duration in a specific direction
    func RotateImage(_ imageView: UIImageView, duration: Double, direction: Double){
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear, animations: { () -> Void in
            imageView.transform = imageView.transform.rotated(by: CGFloat(direction*(Double.pi/2)))
        }) { (finished) -> Void in
            self.RotateImage(imageView, duration: duration, direction: direction)
        }
    }
    
    //Get Current ISS Location by calling ISS Location API
    func SetCurrentISSLocation(_ showAll:Bool){
        
        //Update UI on main thread
        DispatchQueue.main.async {
            
            //Disable Buttons as system attempts to get latest ISS location
            self.issLocationButton.isEnabled = false;
            self.showAllButton.isEnabled = false;
            
            //Configure the annotation location on map for ISS
            self.issLocation = CLLocationCoordinate2D(latitude: self.issCurrentLatitude, longitude: self.issCurrentLongitude);
            self.issAnnotation.coordinate = self.issLocation;
            self.mapView.addAnnotation(self.issAnnotation);
            self.issLocationButton.isEnabled = true;
            self.showAllButton.isEnabled = true;
            
            //Either Focus on just the ISS location after load or on both user and ISS depending on showAll flag
            if(showAll){
                self.FocusOnBothLocations()
            }else{
                self.FocusOnISSLocation()
            }
            
        }
    }
    
    func GetCurrentISSLocation(showAll:Bool){
        
        guard let currentISSURL = URL(string: "http://api.open-notify.org/iss-now.json") else{return}
        
        let dataTask = URLSession.shared.dataTask(with: currentISSURL){ (data, response, error) in
            
            if (error != nil) {
                sendAlert(message: String.init(describing: error!.localizedDescription))
            }else {
                // Attempt to Serialize data into JSON
                if let data = data, let dataDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]{
                    //If ISS Position exists in data...
                    if let dict = dataDict, let issCurrentLocation = dict["iss_position"] as? [String:String]{
                        //If latitude and longitude are retrieved correctly...
                        if let issLatitude = Double(issCurrentLocation["latitude"] as! String), let issLongitude = Double(issCurrentLocation["longitude"] as! String){
                            self.issCurrentLatitude = issLatitude
                            self.issCurrentLongitude = issLongitude
                            self.SetCurrentISSLocation(showAll)
                        }
                    }
                }
            }
            
        }
            dataTask.resume()
        
    }
        
    

}
