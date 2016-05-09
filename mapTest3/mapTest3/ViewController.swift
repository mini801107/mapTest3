//
//  ViewController.swift
//  mapTest3
//
//  Created by 蔡佳旅 on 2016/5/4.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation //for current location

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate
{
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var currentLocation = CLLocation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Get current location */
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        self.mapView.showsUserLocation = true
        
        /* Long press to get arbitrary position */
        let lpgr = UILongPressGestureRecognizer(target:self, action:#selector(ViewController.handleLongPress(_:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        self.mapView.addGestureRecognizer(lpgr)
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }

    @IBAction func searchButtonTapped(sender: AnyObject) {
        let nearby_poi_aes_function = "http://deh.csie.ncku.edu.tw/dehencode/json/nearbyPOIs_AES"
        let client_ip = "http://deh.csie.ncku.edu.tw/deh/functions/get_client_ip.php"
        
        var url = nearby_poi_aes_function + "?"
        url += ("lat=" + "\(currentLocation.coordinate.latitude)")
        url += ("&lng=" + "\(currentLocation.coordinate.longitude)")
        url += ("&dist=" + "100")
        url += ("&userlat=" + "\(currentLocation.coordinate.latitude)")
        url += ("&userlng=" + "\(currentLocation.coordinate.longitude)")
        
        /* Send HTTP GET request */
        let myURL = NSURL(string: url)
        let request = NSMutableURLRequest(URL: myURL!)
        request.HTTPMethod = "GET"
        
        var encryptedData = NSData()
        var decodedString = NSString()
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            if error != nil
            {
                print("error = \(error)")
                return
            }
            encryptedData = data!
            decodedString = NSString(data: data!, encoding: NSUTF8StringEncoding)!
            print("\ntextFormWeb = \(decodedString)")

        })
        task.resume()
        
        //get IP for key
        let myURL_ip = NSURL(string: client_ip)
        let request_ip = NSMutableURLRequest(URL: myURL_ip!)
        request_ip.HTTPMethod = "GET"
        
        var ipString = NSString()
        let task_ip = NSURLSession.sharedSession().dataTaskWithRequest(request_ip, completionHandler: {data, response, error -> Void in
            if error != nil
            {
                print("error = \(error)")
                return
            }
            
            ipString = NSString(data: data!, encoding: NSUTF8StringEncoding)!
        })
        task_ip.resume()
        
        //decryption
        do{
            let originalData = try RNCryptor.decryptData(encryptedData, password: ipString as String)
            print(originalData)
        } catch {
            print(error)
        }
      
    }
    
    // MARK : - Location Delegate Methods
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        currentLocation = locations.last!
        
        print("latitude = \(currentLocation.coordinate.latitude), longitude = \(currentLocation.coordinate.longitude)\n")
        
        let center = CLLocationCoordinate2D(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        
        self.mapView.setRegion(region, animated: true)
        self.locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Errors: " + error.localizedDescription)
    }
    
    // MARK : - Long Press Delegate Mathods
    var previousAnnotation = MKPointAnnotation()
    func handleLongPress(gestureReconizer: UILongPressGestureRecognizer)
    {
        if gestureReconizer.state != UIGestureRecognizerState.Ended
        {
            let touchLocation = gestureReconizer.locationInView(mapView)
            let locationCoordinate = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
            
            //create an MKPointAnnotation object
            let newAnnotation = MKPointAnnotation()
            newAnnotation.coordinate = locationCoordinate
            newAnnotation.title = "You tapped at"
            newAnnotation.subtitle = String(format: "(%.6f, %6f)", locationCoordinate.latitude, locationCoordinate.longitude)
            
            if previousAnnotation.title != nil {
                mapView.removeAnnotation(previousAnnotation)
            }
            mapView.addAnnotation(newAnnotation)
            previousAnnotation = newAnnotation
            
            return
        }
        if gestureReconizer.state != UIGestureRecognizerState.Began{
            return
        }
    }

}

