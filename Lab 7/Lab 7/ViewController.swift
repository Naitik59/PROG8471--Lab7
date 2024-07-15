//
//  ViewController.swift
//  Lab 7
//
//  Created by Naitik Ratilal Patel on 11/07/24.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    @IBOutlet weak var currentSpeedLbl: UILabel!
    @IBOutlet weak var maxSpeedLbl: UILabel!
    @IBOutlet weak var averageSpeedLbl: UILabel!
    @IBOutlet weak var distanceLbl: UILabel!
    @IBOutlet weak var maxAccelerationSpeedLbl: UILabel!
    @IBOutlet weak var overSpeedBarView: UIView!
    @IBOutlet weak var overSpeedLbl: UILabel!
    @IBOutlet weak var bottomBarView: UIView!
    @IBOutlet weak var tripStatusLbl: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var lastLocation: CLLocation?
    var lastSpeed: CLLocationSpeed = 0
    var totalDistance: CLLocationDistance = 0
    var maxSpeed: CLLocationSpeed = 0
    var maxAcceleration: Double = 0
    var startTime: Date?
    var isDriving = false
    var isSpeedOverlimited: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
    }
    
    @IBAction func startDrive(_ sender: UIButton) {
        DispatchQueue.global().async { [self] in
            if CLLocationManager.locationServicesEnabled() {
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.startUpdatingLocation()
                isDriving = true
                resetMetrics()
                
                DispatchQueue.main.async {
                    self.tripStatusLbl.text = "Trip started"
                    self.bottomBarView.backgroundColor = .systemGreen
                }
            }
        }
    }
    
    @IBAction func stopDrive(_ sender: UIButton) {
        locationManager.stopUpdatingLocation()
        isDriving = false
        self.tripStatusLbl.text = "Trip stopped"
        self.overSpeedLbl.text = ""
        self.isSpeedOverlimited = false
        resetMetrics()
    }
    
    func calculateAverageSpeed() -> Double {
        guard let startTime = startTime, let endTime = lastLocation?.timestamp else { return 0 }
        let totalTime = endTime.timeIntervalSince(startTime)
        let averageSpeed = (totalDistance / totalTime) * 3.6
        return averageSpeed
    }
    
    func displayResults() {
        let averageSpeed = calculateAverageSpeed()
        self.currentSpeedLbl.text = "\(String(format: "%.2f", lastSpeed)) km/h"
        self.distanceLbl.text = "\(String(format: "%.2f", totalDistance / 1000)) km"
        self.maxSpeedLbl.text = "\(String(format: "%.2f", maxSpeed)) km/h"
        self.averageSpeedLbl.text = "\(String(format: "%.2f", averageSpeed)) km/h"
        self.maxAccelerationSpeedLbl.text = "\(String(format: "%.2f", maxAcceleration)) m/s²"
    }
    
    func resetMetrics() {
        DispatchQueue.main.async { [self] in
            totalDistance = 0
            maxSpeed = 0
            maxAcceleration = 0
            lastLocation = nil
            lastSpeed = 0
            overSpeedBarView.backgroundColor = .systemGreen
            bottomBarView.backgroundColor = .gray
            
            displayResults()
        }
    }
}

//MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations
                         locations: [CLLocation]) {
        
        guard let location = locations.last else { return }
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
        
        mapView.showsUserLocation = true
        
        if let lastLocation = lastLocation {
            let distance = location.distance(from: lastLocation)
            let timeInterval = location.timestamp.timeIntervalSince(lastLocation.timestamp)
            totalDistance += distance
            
            let speed = distance / timeInterval
            let speedKmh = speed * 3.6
            maxSpeed = max(maxSpeed, speedKmh)
            
            let acceleration = (speed - lastSpeed) / timeInterval
            maxAcceleration = max(maxAcceleration, acceleration)
            
            lastSpeed = speedKmh
            
            if speedKmh > 115 && !isSpeedOverlimited {
                isSpeedOverlimited = true
                overSpeedLbl.text = "You travelled \(String(format: "%.2f", distance / 1000)) km, before over speeding"
                overSpeedBarView.backgroundColor = .red
            }
            
            displayResults()
        } else {
            startTime = location.timestamp
        }
        
        lastLocation = location
    }
}
