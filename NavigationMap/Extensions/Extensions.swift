import Foundation
import YandexMapKit

extension ViewController:YMKMapCameraListener{
    
    func onCameraPositionChanged(with map: YMKMap, cameraPosition: YMKCameraPosition, cameraUpdateSource: YMKCameraUpdateSource, finished: Bool) {
        
        let pinPoint = YMKPoint(latitude: cameraPosition.target.latitude, longitude: cameraPosition.target.longitude)
        
        guard let lastLocation = YMKLocationManager.lastKnownLocation()?.position else { return }
        currentLocationPoint = lastLocation
        directonLocationPoint = pinPoint
        return
    }
}

