//
//  ViewController.swift
//  MapKitSample
//
//  Created by Hikaru Kuroda on 2023/04/30.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController {
    
    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    
    private var currentLocation = CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917) // 初期値は東京駅
    
    private var userLocationAnnotationView: MKAnnotationView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        mapView.delegate = self
        
        mapView.isHidden = true
        mapView.showsUserLocation = true
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        mapView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        locationManager.requestWhenInUseAuthorization()
        
        initMapViewSpan()
        mapView.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    private func initMapViewSpan() {
        let span = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
        let region = MKCoordinateRegion(center: currentLocation, span: span)
        mapView.setRegion(region, animated: false)
    }
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(
        _ mapView: MKMapView,
        viewFor annotation: MKAnnotation
    ) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            var userLocationAnnotation = mapView.dequeueReusableAnnotationView(withIdentifier: "userLocation")
            if userLocationAnnotation == nil {
                userLocationAnnotation = MKAnnotationView(annotation: annotation, reuseIdentifier: "userLocation")
            }
            
            let image = UIImage(systemName: "location.north.circle")
            userLocationAnnotation?.image = image
            userLocationAnnotation?.annotation = annotation
            userLocationAnnotation?.frame = .init(x: 0, y: 0, width: 30, height: 30)
            
            self.userLocationAnnotationView = userLocationAnnotation
            return userLocationAnnotation
        }
        
        return nil
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    // 位置情報が更新されたとき
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
    }
    
    // 方向が更新されたとき
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard let userLocationAnnotationView = userLocationAnnotationView else { return }
        let angle = CGFloat(newHeading.trueHeading) * .pi / 180
        let transform = CGAffineTransform(rotationAngle: angle)
        userLocationAnnotationView.transform = transform
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined, .denied:
            break
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                mapView.setCenter(currentLocation, animated: false)
            }
            
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
        
        let alert = UIAlertController(title: "位置情報取得に失敗しました。再起動してください", message: "\(error.localizedDescription)", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "ok", style: .default)
        alert.addAction(okAction)
        
        self.present(alert, animated: true)
    }
}
