//
//  ViewController.swift
//  MapTest
//
//  Created by 持田侑菜 on 2020/08/13.
//  Copyright © 2020 持田侑菜. All rights reserved.
//
//  Requesting Authorization for Location Services
//  https://developer.apple.com/documentation/corelocation/requesting_authorization_for_location_services
//
//  Using the Visits Location Service
//  https://developer.apple.com/documentation/corelocation/getting_the_user_s_location/using_the_visits_location_service
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var locManager: CLLocationManager!
    @IBOutlet var longPressGesRec: UILongPressGestureRecognizer!
    var pointAno: MKPointAnnotation = MKPointAnnotation()
    let geocoder = CLGeocoder()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        locManager = CLLocationManager()
        locManager.delegate = self
        
        // 位置情報利用の許可を得る
        locManager.requestWhenInUseAuthorization()
        
        initMap()
        
        longPressGesRec.delegate = self // 不要？
    }
    
    // 地図の初期化関数
    func initMap() {
        // 縮尺
        var region: MKCoordinateRegion = mapView.region
        region.span.latitudeDelta = 0.02
        region.span.longitudeDelta = 0.02
        mapView.setRegion(region, animated: true)
        
        // ユーザーを中心に地図を表示
        mapView.userTrackingMode = .follow
    }
    
    // 位置情報利用の認証が変更されたとき
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    }

    // ロングタップ検出
    @IBAction func mapViewDidLongPress(_ sender: UILongPressGestureRecognizer) {
        // ロングタップ開始
        if sender.state == .began {
            print("ロングタップ開始")
            mapView.removeAnnotation(pointAno)
        }
        // ロングタップ終了
        if sender.state == .ended {  // ifの前にelseがあってもいい（あったほうがいい？）
            print("ロングタップ終了")
            
            // タップした位置の緯度と経度を算出
            let tapPoint = sender.location(in: view)
            let center = mapView.convert(tapPoint, toCoordinateFrom: mapView)
            
            let lonStr = center.longitude.description
            let latStr = center.latitude.description
            print("lon : " + lonStr)
            print("lat : " + latStr)
            
            let lonNum = Double(lonStr)!
            let latNum = Double(latStr)!
            
            let location = CLLocation(latitude: latNum, longitude: lonNum)
            geocoder.reverseGeocodeLocation(location, preferredLocale: nil, completionHandler: GeocodeCompHandler(placemarks:error:))
            
            // ピンを定義
            self.pointAno.coordinate = center
            // ピンを立てる
            self.mapView.addAnnotation(self.pointAno)
        }
    }
    
    // reverseGeocodeLocation(_:preferredLocale:completionHandler:)の第3引数
    // 何かに使えそう&クロージャに慣れないので外側に関数を作成した
    func GeocodeCompHandler(placemarks: [CLPlacemark]?, error: Error?) {
        guard let placemark = placemarks?.first, error == nil,
            let administrativeArea = placemark.administrativeArea, //県
            let locality = placemark.locality, // 市区町村
            let throughfare = placemark.thoroughfare, // 丁目を含む地名
            let subThoroughfare = placemark.subThoroughfare // 番地
            else {
                return
        }
        print(administrativeArea + locality + throughfare + subThoroughfare)
        self.pointAno.title = administrativeArea + locality + throughfare + subThoroughfare
    }
}

