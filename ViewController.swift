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
    var searchAnnotationArray = [MKPointAnnotation]()
    let geocoder = CLGeocoder()
    
    var lat: String = ""
    var lon: String = ""

    @IBOutlet weak var placeSearchBar: UISearchBar!
    
    @IBOutlet weak var detailsView: UIView!
    @IBOutlet weak var detailsViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var placeNameLabel: UILabel!
    @IBOutlet weak var placeAddressLabel: UILabel!
    @IBOutlet weak var directionsButton: UIButton!
    @IBOutlet weak var addPlanButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        hiddenDetailsView()
        
        // 詳細ビュー
        detailsView.layer.masksToBounds = true
        detailsView.layer.cornerRadius = 20
        
        // 詳細ビューの予定を追加ボタン
        addPlanButton.setTitleColor(.white, for: .normal)
        addPlanButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
        addPlanButton.layer.backgroundColor = UIColor.orange.cgColor
        addPlanButton.layer.masksToBounds = true
        addPlanButton.layer.cornerRadius = 8
        
        // 詳細ビューの経路を表示ボタン
        directionsButton.setTitleColor(.white, for: .normal)
        directionsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
        directionsButton.layer.backgroundColor = UIColor.blue.cgColor
        directionsButton.layer.masksToBounds = true
        directionsButton.layer.cornerRadius = 8
        
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
            hiddenDetailsView()
        }
    }

    // ロングタップ検出
    @IBAction func mapViewDidLongPress(_ sender: UILongPressGestureRecognizer) {
        // ロングタップ開始
        if sender.state == .began {
            print("ロングタップ開始")
            
            // 古いピンを削除する
            mapView.removeAnnotation(annotation)
            mapView.removeAnnotations(searchAnnotationArray)
        }
        // ロングタップ終了
        if sender.state == .ended {  // ifの前にelseがあってもいい（あったほうがいい？）
            print("ロングタップ終了")
            
            // prepare(for:sender:) で場合分けするため配列を空にする
            searchAnnotationArray.removeAll()
            
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
        placeAddressLabel.text = administrativeArea + locality + throughfare + subThoroughfare
    }
    
    // ピンの詳細設定
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 現在地にはピンを立てない
        if annotation is MKUserLocation {
            return nil
        }
        
        // 吹き出し内の･･･ボタン
        let detailsButton = UIButton()
        detailsButton.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        detailsButton.setTitle("･･･", for: .normal)
        detailsButton.setTitleColor(.orange, for: .normal)
        detailsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18.0)
        
        // 配列が空のとき（ロングタップでピンを立てたとき）
        if searchAnnotationArray.isEmpty == true {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
            // 吹き出しを表示
            annotationView.canShowCallout = true
            
            // 吹き出しの右側にボタンをセット
            annotationView.rightCalloutAccessoryView = detailsButton
            
            return annotationView
            
        }
            
        // 配列が空ではないとき（検索でピンを立てたとき）
        else {
            let searchAnnotationView = MKPinAnnotationView(annotation: searchAnnotationArray as? MKAnnotation, reuseIdentifier: nil)
            // 吹き出しを表示
            searchAnnotationView.canShowCallout = true
            
            // 吹き出しの右側にボタンをセット
            searchAnnotationView.rightCalloutAccessoryView = detailsButton
            
            return searchAnnotationView
        }
    }
    
    // 吹き出しアクセサリー押下時
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // ･･･ボタンで詳細ビューを表示
        if control == view.rightCalloutAccessoryView {
            displayDetailsView()
            
            // 配列が空のとき（ロングタップでピンを立てたとき）
            if searchAnnotationArray.isEmpty == true {
                placeNameLabel.text = annotation.title
            }
            
            // 配列が空ではないとき（検索でピンを立てたとき）
            else if searchAnnotationArray.isEmpty == false {
                // 選択されているピンを新たな配列に格納
                let selectedSearchAnnotationArray = mapView.selectedAnnotations
                
                // 選択されているピンは1つのため、0番目を取り出す
                let selectedSearchAnnotation = selectedSearchAnnotationArray[0]
                
                // ピンの緯度と経度を取得
                let latNum = selectedSearchAnnotation.coordinate.latitude
                let lonNum = selectedSearchAnnotation.coordinate.longitude
                
                let location = CLLocation(latitude: latNum, longitude: lonNum)
                geocoder.reverseGeocodeLocation(location, preferredLocale: nil, completionHandler: GeocodeCompHandler(placemarks:error:))
                
                if let selectedSearchAnnotationTitle = selectedSearchAnnotation.title {
                    placeNameLabel.text = selectedSearchAnnotationTitle
                }
            }
        }
    }
    
    // 経路を表示ボタンクリック時
    @IBAction func displayDirections(_ sender: Any) {
        // 配列が空のとき（ロングタップでピンを立てたとき）
        if searchAnnotationArray.isEmpty == true {
            let coordinate = CLLocationCoordinate2D(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placemark)
            
            let options: [String: Any]? = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] // 車で移動
            
            mapItem.openInMaps(launchOptions: options)
        }
        
        // 配列が空ではないとき（検索でピンを立てたとき）
        else if searchAnnotationArray.isEmpty == false {
            // 選択されているピンを新たな配列に格納
            let selectedSearchAnnotationArray = mapView.selectedAnnotations
            
            // 選択されているピンは1つのため、0番目を取り出す
            let selectedSearchAnnotation = selectedSearchAnnotationArray[0]
            
            let coordinate = CLLocationCoordinate2D(latitude: selectedSearchAnnotation.coordinate.latitude, longitude: selectedSearchAnnotation.coordinate.longitude)
            let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placemark)
            
            let options: [String: Any]? = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] // 車で移動
            
            mapItem.openInMaps(launchOptions: options)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("検索")
        mapView.removeAnnotation(annotation)
        mapView.removeAnnotations(searchAnnotationArray)
        hiddenDetailsView()
        
        // 前回の検索結果を配列から取り除く
        searchAnnotationArray.removeAll()
        
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
                    
                    // タイトルに場所の名前を表示
                    searchAnnotation.title = searchLocation.placemark.name
                    // ピンを立てる
                    mapView.addAnnotation(searchAnnotation)
                    
                    // searchAnnotation配列にピンをセット
                    searchAnnotationArray.append(searchAnnotation)
                    
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

        // 0番目のピンを中心に表示
        if searchAnnotationArray.isEmpty == false {
            let searchAnnotation = searchAnnotationArray[0]
            let center = CLLocationCoordinate2D(latitude: searchAnnotation.coordinate.latitude, longitude: searchAnnotation.coordinate.longitude)
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
    
    func displayDetailsView() {
        detailsViewHeight.constant = 150
        placeNameLabel.isHidden = false
        placeAddressLabel.isHidden = false
        directionsButton.isHidden = false
        addPlanButton.isHidden = false
    }
    
    func hiddenDetailsView() {
        detailsViewHeight.constant = 0
        placeNameLabel.isHidden = true
        placeAddressLabel.isHidden = true
        directionsButton.isHidden = true
        addPlanButton.isHidden = true
    }
    
    // 遷移時に住所と緯度と経度を渡す
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "toReceiveVC" {
            let receiveVC = segue.destination as! ReceiveViewController
            
            // 配列が空のとき（ロングタップでピンを立てたとき）
            if searchAnnotationArray.isEmpty == true {
                receiveVC.address = self.annotation.title ?? ""
                receiveVC.lat = self.lat
                receiveVC.lon = self.lon                
            }
            
            // 配列が空ではないとき（検索でピンを立てたとき）
            else {
                // 選択されているピンを新たな配列に格納
                let selectedSearchAnnotationArray = mapView.selectedAnnotations
                
                // 選択されているピンは1つのため、0番目を取り出す
                let selectedSearchAnnotation = selectedSearchAnnotationArray[0]
                
                // ピンの緯度と経度を取得
                let latStr = selectedSearchAnnotation.coordinate.latitude.description
                let lonStr = selectedSearchAnnotation.coordinate.longitude.description
                
                // 選択されているピンからタイトルを取得
                if let selectedSearchAnnotationTitle = selectedSearchAnnotation.title {
                    receiveVC.address = selectedSearchAnnotationTitle ?? ""
                    receiveVC.lat = latStr
                    receiveVC.lon = lonStr
                }
            }
        }
    }
    
}

