//
//  CampusViewController.swift
//  CampusMap
//
//  Created by Chun on 2018/11/26.
//  Copyright © 2018 Nemoworks. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


class CampusViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var campus = Campus(filename: "Campus")
    var selectedOptions : [MapOptionsType] = []
    let locationManager = CLLocationManager()
    var destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 32.111045, longitude: 118.962997)))
    var userLocation: CLLocation?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let latDelta = campus.overlayTopLeftCoordinate.latitude - campus.overlayBottomRightCoordinate.latitude
        
        // Think of a span as a tv size, measure from one corner to another
        let span = MKCoordinateSpan.init(latitudeDelta: fabs(latDelta), longitudeDelta: 0.0)
        let region = MKCoordinateRegion.init(center: campus.midCoordinate, span: span)
        
        mapView.region = region
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        (segue.destination as? MapOptionsViewController)?.selectedOptions = selectedOptions
    }
    
    
    // MARK: Helper methods
    func loadSelectedOptions() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        for option in selectedOptions {
            switch (option) {
            case .mapPOIs:
                self.addPOIs()
            case .mapBoundary:
                self.addBoundary()
            }
        }
    }
    
    
    @IBAction func closeOptions(_ exitSegue: UIStoryboardSegue) {
        guard let vc = exitSegue.source as? MapOptionsViewController else { return }
        selectedOptions = vc.selectedOptions
        loadSelectedOptions()
    }
    
    
    //    func addOverlay() {
    //        let overlay = ParkMapOverlay(park: park)
    //        mapView.addOverlay(overlay)
    //    }
    //
    
    func addBoundary() {
        mapView.addOverlay(MKPolygon(coordinates: campus.boundary, count: campus.boundary.count))
    }
    
    func addPOIs() {
        guard let pois = Campus.plist("CampusPOI") as? [[String : String]] else { return }
        
        for poi in pois {
            let coordinate = Campus.parseCoord(dict: poi, fieldName: "location")
            let title = poi["name"] ?? ""
            let typeRawValue = Int(poi["type"] ?? "0") ?? 0
            let type = POIType(rawValue: typeRawValue) ?? .misc
            let subtitle = poi["subtitle"] ?? ""
            let annotation = POIAnnotation(coordinate: coordinate, title: title, subtitle: subtitle, type: type)
            mapView.addAnnotation(annotation)
        }
    }
    
    @IBAction func mapTypeChanged(_ sender: UISegmentedControl) {
        mapView.mapType = MKMapType.init(rawValue: UInt(sender.selectedSegmentIndex)) ?? .standard
    }
    
    func getDirections() {
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.requestsAlternateRoutes = false
        let directions = MKDirections(request: request)
        directions.calculate(completionHandler: {(response, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                if let response = response {
                    self.showRoute(response)
                }
            }
        })
    }
    
    func showRoute(_ response: MKDirections.Response) {
        for route in response.routes {
            mapView.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
            for step in route.steps {
                print(step.instructions)
            }
        }
        if let coordinate = userLocation?.coordinate {
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
            mapView.setRegion(region, animated: true)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)
        //    1、获取在控件上点击的点
        let point = touches.first?.location(in: mapView)
        //    2、将控件上面的点(CGPoint),转为经纬度
        let coordinate = mapView.convert(point!, toCoordinateFrom: mapView)
        //    3、创建大头针数据模型,并添加到地图上：注：必须先设置title和subTitle的占位字
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "nanjing"
        mapView.addAnnotation(annotation)
        //_ = addAnnotation(coordinate: coordinate, title: "城市", subTitle: "地址")
        destination = MKMapItem(placemark: MKPlacemark(coordinate:coordinate))
        getDirections()
    }
    
    /*func addAnnotation(coordinate:CLLocationCoordinate2D, title:String, subTitle:String) -> MKPointAnnotation{
        //①通过模型创建大头针；
        let annotation = MKPointAnnotation()
        //②确定大头针的经纬度(在地图上显示的位置)；
        annotation.coordinate = coordinate
        //将点击的那个点的经纬度进行 反地理编码，得到弹框要显示的标题和子标题
        //获取需要反地理编码的经纬度，懒加载地理编码对象：CLGeocoder
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder: CLGeocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemark, error) -> Void in
            DispatchQueue.main.async {
                if(error == nil)
                {
                    let mark = placemark![0]
                    //街道，城市，区划，省份，邮编，国家
                    ////③通过地标对象获取城市、详细地址, 设置大头针弹框的标题和子标题；
                    annotation.title = mark.locality
                    annotation.subtitle = (mark.locality)! + (mark.subLocality)!
                    annotation.subtitle = annotation.subtitle! + (mark.name)!
                }
                else
                {
                    print(error!)
                }
            }
        }
        //④添加到地图上
        mapView.addAnnotation(annotation)
        return annotation
    }*/
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}


// MARK: - MKMapViewDelegate
extension CampusViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
       if overlay is MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = UIColor.red
            return lineView
        } else if overlay is MKPolygon {
            let polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView.strokeColor = UIColor.blue
            polygonView.lineWidth = CGFloat(3.0)
            return polygonView
        }
        
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = POIAnnotationView(annotation: annotation, reuseIdentifier: "POI")
        annotationView.canShowCallout = true
        return annotationView
    }
}

extension CampusViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0]
        self.getDirections()
        let circle = MKCircle(center: (userLocation?.coordinate)!, radius: 10000)
        mapView.addOverlay(circle)
    }
}
