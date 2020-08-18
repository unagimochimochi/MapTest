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

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var locManager: CLLocationManager!
    @IBOutlet var tapGesRec: UITapGestureRecognizer!
    @IBOutlet var longPressGesRec: UILongPressGestureRecognizer!
    var pointAno: MKPointAnnotation = MKPointAnnotation()
    let geocoder = CLGeocoder()
    
    var lon: String = ""
    var lat: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        
        locManager = CLLocationManager()
        locManager.delegate = self
        
        // 位置情報利用の許可を得る
        locManager.requestWhenInUseAuthorization()
        
        initMap()
        
        tapGesRec.delegate = self // 不要？
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
    
    // タップ検出
    @IBAction func mapViewDidTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            print("タップ")
            mapView.removeAnnotation(pointAno)
        }
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
            
            // 変数にタップした位置の緯度と経度をセット
            lon = lonStr
            lat = latStr
                        
            let lonNum = Double(lonStr)!
            let latNum = Double(latStr)!
            
            let location = CLLocation(latitude: latNum, longitude: lonNum)
            geocoder.reverseGeocodeLocation(location, preferredLocale: nil, completionHandler: GeocodeCompHandler(placemarks:error:))
            
            // ピンの座標
            pointAno.coordinate = center
            // ピンを立てる
            mapView.addAnnotation(pointAno)
            // ピンを最初から選択状態にする
            mapView.selectAnnotation(pointAno, animated: true)
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
        
        self.pointAno.title = administrativeArea + locality + throughfare + subThoroughfare
    }
    
    // ピンの詳細設定
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 現在地にはピンを立てない
        if annotation is MKUserLocation {
            return nil
        }
        
        let anoView = MKPinAnnotationView(annotation: pointAno, reuseIdentifier: nil)
        
        // 吹き出しを表示
        anoView.canShowCallout = true
        
        // 吹き出し内の予定を追加ボタン
        let addPlanButton = UIButton()
        addPlanButton.frame = CGRect(x: 0, y: 0, width: 85, height: 36)
        addPlanButton.setTitle("予定を追加", for: .normal)
        addPlanButton.setTitleColor(.white, for: .normal)
        addPlanButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
        addPlanButton.layer.backgroundColor = UIColor.orange.cgColor
        addPlanButton.layer.masksToBounds = true
        addPlanButton.layer.cornerRadius = 8
        
        // 吹き出しの右側にボタンをセット
        anoView.rightCalloutAccessoryView = addPlanButton
        
        return anoView
    }
    
    // 吹き出しアクセサリー押下時
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // 右側のボタンでReceiveVCに遷移
        if control == view.rightCalloutAccessoryView {
            self.performSegue(withIdentifier: "toReceiveVC", sender: nil)
        }
    }
    
    // 遷移時に住所と緯度と経度を渡す
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        if identifier == "toReceiveVC" {
            let receiveVC = segue.destination as! ReceiveViewController
            receiveVC.address = self.pointAno.title ?? ""
            receiveVC.lon = self.lon
            receiveVC.lat = self.lat
        }
    }
}

