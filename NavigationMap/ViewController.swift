//
//  ViewController.swift
//  NavigationMap
//
//  Created by Baudunov Rapkat on 4/10/20.
//  Copyright © 2020 Baudunov Rapkat. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var adressLabel: UILabel!
    
    let locationManager = CLLocationManager()
    let regionInMeters:Double = 10000
    var previosLocation: CLLocation?
    var directionArray: [MKDirections] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //mapView.delegate = self
        checkLocationServices()
    }
    
    func setupLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func centerUserLocation(){
        if let location = locationManager.location?.coordinate{
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func checkLocationServices(){
        if CLLocationManager.locationServicesEnabled(){
            setupLocationManager()
            checkLocationAuthorization()
        }else{
            
        }
    }
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            startTrakingUserLocation()
        case .denied:
            // Show alert instructing them how to turn on permissions
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // Show an alert letting them know what's up
            break
        case .authorizedAlways:
            break
        }
    }
    func startTrakingUserLocation(){
        mapView.showsUserLocation = true
        centerUserLocation()
        locationManager.startUpdatingLocation()
        previosLocation = getCenterLocation(for: mapView)
    }
    
    func getCenterLocation(for mapView:MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func getDirections(){
        guard let location = locationManager.location?.coordinate else { return }
        
        let request = createDirectionRequest(from: location)
        let direction = MKDirections(request: request)
        cleanMap(withNew: direction)
        
        direction.calculate { [unowned self] (response,error) in
            guard let response = response else { return }
            
            for route in response.routes{
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func createDirectionRequest(from coordicate: CLLocationCoordinate2D) -> MKDirections.Request{
        let DestinationCoordinate       = getCenterLocation(for: mapView).coordinate
        let startPoint                  = MKPlacemark(coordinate: coordicate)
        let destination                 = MKPlacemark(coordinate: DestinationCoordinate)
        
        let request                     = MKDirections.Request()
        request.source                  = MKMapItem(placemark: startPoint)
        request.destination             = MKMapItem(placemark: destination)
        request.transportType           = .automobile
        request.requestsAlternateRoutes = true
        
        return request
        
    }
    
    func cleanMap(withNew directions:MKDirections){
        mapView.removeOverlays(mapView.overlays)
        directionArray.append(directions)
        let _ = directionArray.map{ $0.cancel()}
    }
    
    
    @IBAction func GoButton(_ sender: UIButton) {
        getDirections()
    }
}

extension ViewController: CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}

extension ViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapView)
        let geoCoder = CLGeocoder()
        
        guard let previosLocation = self.previosLocation else { return }
        
        guard center.distance(from: previosLocation) > 50 else { return }
        self.previosLocation = center
        
        geoCoder.reverseGeocodeLocation(center){ [weak self] (placemarks,error) in
            guard let self = self else { return }
            
            if let _ = error {
                // something
                return
            }
            guard let placemark = placemarks?.first else{
                return
            }
            
           // let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            
            DispatchQueue.main.async {
                self.adressLabel.text = " \(streetName)"
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        
        return renderer
    }
}
