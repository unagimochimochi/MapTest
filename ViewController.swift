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

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var locManager: CLLocationManager!
    @IBOutlet var tapGesRec: UITapGestureRecognizer!
    @IBOutlet var longPressGesRec: UILongPressGestureRecognizer!
    var annotation: MKPointAnnotation = MKPointAnnotation()
    let geocoder = CLGeocoder()
    
    var lat: String = ""
    var lon: String = ""
    
    var searchAnnotationArray = [MKPointAnnotation]()
    var searchAnnotationTitleArray = [String]()
    var searchAnnotationLatArray = [String]()
    var searchAnnotationLonArray = [String]()

    @IBOutlet weak var placeSearchBar: UISearchBar!
    
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
        
        placeSearchBar.delegate = self
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
            mapView.removeAnnotation(annotation)
        }
    }

    // ロングタップ検出
    @IBAction func mapViewDidLongPress(_ sender: UILongPressGestureRecognizer) {
        // ロングタップ開始
        if sender.state == .began {
            print("ロングタップ開始")
            mapView.removeAnnotation(annotation)
        }
        // ロングタップ終了
        if sender.state == .ended {  // ifの前にelseがあってもいい（あったほうがいい？）
            print("ロングタップ終了")
            
            // prepare(for:sender:) で場合分けするため配列を空にする
            searchAnnotationTitleArray.removeAll()
 
            
            // タップした位置の緯度と経度を算出
            let tapPoint = sender.location(in: view)
            let center = mapView.convert(tapPoint, toCoordinateFrom: mapView)
            
            let latStr = center.latitude.description
            let lonStr = center.longitude.description
            
            print("lat : " + latStr)
            print("lon : " + lonStr)
            
            // 変数にタップした位置の緯度と経度をセット
            lat = latStr
            lon = lonStr
            
            let latNum = Double(latStr)!
            let lonNum = Double(lonStr)!
            
            let location = CLLocation(latitude: latNum, longitude: lonNum)
            geocoder.reverseGeocodeLocation(location, preferredLocale: nil, completionHandler: GeocodeCompHandler(placemarks:error:))
            
            // ピンの座標
            annotation.coordinate = center
            // ピンを立てる
            mapView.addAnnotation(annotation)
            // ピンを最初から選択状態にする
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    // reverseGeocodeLocation(_:preferredLocale:completionHandler:)の第3引数
    // クロージャに慣れないので外側に関数を作成
    func GeocodeCompHandler(placemarks: [CLPlacemark]?, error: Error?) {
        guard let placemark = placemarks?.first, error == nil,
            let administrativeArea = placemark.administrativeArea, //県
            let locality = placemark.locality, // 市区町村
            let throughfare = placemark.thoroughfare, // 丁目を含む地名
            let subThoroughfare = placemark.subThoroughfare // 番地
            else {
                return
        }
        
        self.annotation.title = administrativeArea + locality + throughfare + subThoroughfare
    }
    
    // ピンの詳細設定
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 現在地にはピンを立てない
        if annotation is MKUserLocation {
            return nil
        }
        
        // 吹き出し内の予定を追加ボタン
        let addPlanButton = UIButton()
        addPlanButton.frame = CGRect(x: 0, y: 0, width: 85, height: 36)
        addPlanButton.setTitle("予定を追加", for: .normal)
        addPlanButton.setTitleColor(.white, for: .normal)
        addPlanButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
        addPlanButton.layer.backgroundColor = UIColor.orange.cgColor
        addPlanButton.layer.masksToBounds = true
        addPlanButton.layer.cornerRadius = 8
        
        // 配列が空のとき（ロングタップでピンを立てたとき）
        if searchAnnotationTitleArray.isEmpty == true {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
            // 吹き出しを表示
            annotationView.canShowCallout = true
            
            // 吹き出しの右側にボタンをセット
            annotationView.rightCalloutAccessoryView = addPlanButton
            
            return annotationView
            
        }
            
        // 配列が空ではないとき（検索でピンを立てたとき）
        else {
            let searchAnnotationView = MKPinAnnotationView(annotation: searchAnnotationArray as? MKAnnotation, reuseIdentifier: nil)
            // 吹き出しを表示
            searchAnnotationView.canShowCallout = true
            
            // 吹き出しの右側にボタンをセット
            searchAnnotationView.rightCalloutAccessoryView = addPlanButton
            
            return searchAnnotationView
        }
    }
    
    // 吹き出しアクセサリー押下時
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // 右側のボタンでReceiveVCに遷移
        if control == view.rightCalloutAccessoryView {
            self.performSegue(withIdentifier: "toReceiveVC", sender: nil)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("検索")
        mapView.removeAnnotation(annotation)
        
        // キーボードをとじる
        self.view.endEditing(true)
        
        // 検索条件を作成
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = placeSearchBar.text
        
        // 検索範囲はMKMapViewと同じ
        request.region = mapView.region
        
        let localSearch = MKLocalSearch(request: request)
        localSearch.start(completionHandler: LocalSearchCompHandler(response:error:))
    }
    
    // start(completionHandler:)の引数
    func LocalSearchCompHandler(response: MKLocalSearch.Response?, error: Error?) -> Void {
        // 検索がヒットしたとき
        if let response = response {
            for searchLocation in (response.mapItems) {
                if error == nil {
                    let searchAnnotation = MKPointAnnotation()
                    // ピンの座標
                    let center = CLLocationCoordinate2DMake(searchLocation.placemark.coordinate.latitude, searchLocation.placemark.coordinate.longitude)
                    searchAnnotation.coordinate = center
                    
                    let latStr = center.latitude.description
                    let lonStr = center.longitude.description
                    
                    // 変数に検索した位置の緯度と経度をセット
                    searchAnnotationLatArray.append(latStr)
                    searchAnnotationLonArray.append(lonStr)
                    
                    // タイトルに場所の名前を表示
                    searchAnnotation.title = searchLocation.placemark.name
                    // ピンを立てる
                    mapView.addAnnotation(searchAnnotation)
                    
                    // searchAnnotation配列にピンをセット
                    searchAnnotationArray.append(searchAnnotation)
                    // searchAnnotationTitle配列に場所の名前をセット
                    searchAnnotationTitleArray.append(searchAnnotation.title ?? "")
                    
                } else {
                    print("error")
                }
            }
        }
        
        // 検索がヒットしなかったとき
        else {
            let dialog = UIAlertController(title: "検索結果なし", message: "ご迷惑をおかけします。\nどうしてもヒットしない場合は住所を入力してみてください！", preferredStyle: .alert)
            // OKボタン
            dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            // ダイアログを表示
            self.present(dialog, animated: true, completion: nil)
        }
        
        if searchAnnotationLatArray.isEmpty == false {
            // String型からDouble型に変換し、0番目の緯度と経度を取り出す
            let searchLocationLatNum = Double(searchAnnotationLatArray[0])!
            let searchLocationLonNum = Double(searchAnnotationLonArray[0])!
            
            // 0番目のピンを中心に表示
            let center = CLLocationCoordinate2D(latitude: searchLocationLatNum, longitude: searchLocationLonNum)
            mapView.setCenter(center, animated: true)
            
        } else {
            print("配列が空")
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("検索キャンセル")
        
        // テキストを空にする
        placeSearchBar.text = ""
        // キーボードをとじる
        self.view.endEditing(true)
    }
    
    // 遷移時に住所と緯度と経度を渡す
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "toReceiveVC" {
            let receiveVC = segue.destination as! ReceiveViewController
            
            // 配列が空のとき（ロングタップでピンを立てたとき）
            if searchAnnotationTitleArray.isEmpty == true {
                receiveVC.address = self.annotation.title ?? ""
                receiveVC.lat = self.lat
                receiveVC.lon = self.lon                
            }
            
            // 配列が空ではないとき（検索でピンを立てたとき）
            else {
                // いま選択されているピンの判別方法がわからない(´･_･`)
                receiveVC.address = self.searchAnnotationTitleArray[0]
                receiveVC.lat = self.searchAnnotationLatArray[0]
                receiveVC.lon = self.searchAnnotationLonArray[0]
            }
        }
    }
    
}

