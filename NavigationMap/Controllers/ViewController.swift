import UIKit
import YandexMapKit
import CoreLocation
import YandexMapKitDirections
import YandexRuntime

class ViewController: UIViewController,YMKUserLocationObjectListener{
    
    var userLocationLayer: YMKUserLocationLayer!
    var currentLocationPoint:YMKPoint!
    var directonLocationPoint:YMKPoint!
    var drivingSession: YMKDrivingSession?
    
    @IBOutlet weak var mapView: YMKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let pinImage = UIImage(named: "pin")
        
        let myImageView:UIImageView = UIImageView()
        myImageView.contentMode = UIView.ContentMode.scaleAspectFit
        myImageView.frame.size.width = 50
        myImageView.frame.size.height = 100
        myImageView.center = self.view.center
        myImageView.image = pinImage
        
        view.addSubview(myImageView)
        
        
        let myButton = UIButton(type: .system)
        myButton.frame = CGRect(x: 20, y: 20, width: 65, height: 65)
        myButton.center = CGPoint(x: 330, y: 590 )
        myButton.setTitle("GO", for: .normal)
        myButton.layer.cornerRadius = 0.5 * myButton.bounds.size.width
        myButton.backgroundColor = .green
        myButton.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        
        view.addSubview(myButton)
        
        centerViewOnUserLocation()
        
    }
    
    
    func onObjectAdded(with view: YMKUserLocationView) {
        
        let pinPlacemark = view.pin.useCompositeIcon()
        
        pinPlacemark.setIconWithName(
            "pin",
            image: UIImage(named:"SearchResult")!,
            style:YMKIconStyle(
                anchor: CGPoint(x: 0.5, y: 0.5) as NSValue,
                rotationType:YMKRotationType.rotate.rawValue as NSNumber,
                zIndex: 1,
                flat: true,
                visible: true,
                scale: 1,
                tappableArea: nil))
        
        view.accuracyCircle.fillColor = UIColor.blue
    }
    
    func onObjectRemoved(with view: YMKUserLocationView) {}
    
    func onObjectUpdated(with view: YMKUserLocationView, event: YMKObjectEvent) {
    }
    
    func centerViewOnUserLocation() {
        if let location = YMKLocationManager.lastKnownLocation()?.position {
            mapView.mapWindow.map.isRotateGesturesEnabled = false
            let map = YMKMapKit.sharedInstance()
            if userLocationLayer == nil{
                userLocationLayer = map.createUserLocationLayer(with: mapView.mapWindow)
                userLocationLayer.isHeadingEnabled = true
                userLocationLayer.setVisibleWithOn(true)
                let userLocation = YMKPoint(latitude: location.latitude, longitude: location.longitude)
                mapView.mapWindow.map.move(with:
                    YMKCameraPosition(target: userLocation, zoom: 14, azimuth: 0, tilt: 0))
                mapView.mapWindow.map.addCameraListener(with: self)
                userLocationLayer.setObjectListenerWith(self)
            }
            
        }
    }
    
    @objc func buttonAction(_ sender:UIButton!){
        mapView.mapWindow.map.mapObjects.clear()
        let requestPoints : [YMKRequestPoint] = [
            YMKRequestPoint(point: currentLocationPoint, type: .waypoint, pointContext: nil),
            YMKRequestPoint(point: directonLocationPoint, type: .waypoint, pointContext: nil),
        ]
        
        let responseHandler = {(routesResponse: [YMKDrivingRoute]?, error: Error?) -> Void in
            if let routes = routesResponse {
                self.onRoutesReceived(routes)
            } else {
                self.onRoutesError(error!)
            }
        }
        let drivingRouter = YMKDirections.sharedInstance().createDrivingRouter()
        drivingSession = drivingRouter.requestRoutes(
            with: requestPoints,
            drivingOptions: YMKDrivingDrivingOptions(),
            routeHandler: responseHandler)
    }
    
    func onRoutesReceived(_ routes: [YMKDrivingRoute]) {
        let mapObjects = mapView.mapWindow.map.mapObjects
        for route in routes {
            mapObjects.addPolyline(with: route.geometry)
        }
    }
    
    func onRoutesError(_ error: Error) {
        let routingError = (error as NSError).userInfo[YRTUnderlyingErrorKey] as! YRTError
        var errorMessage = "Unknown error"
        if routingError.isKind(of: YRTNetworkError.self) {
            errorMessage = "Network error"
        } else if routingError.isKind(of: YRTRemoteError.self) {
            errorMessage = "Remote server error"
        }
        
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
}
