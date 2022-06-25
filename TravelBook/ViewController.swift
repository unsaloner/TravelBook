//
//  ViewController.swift
//  TravelBook
//
//  Created by Unsal Oner on 13.01.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    
//    Kullanıcının konumuyla ilgili işlemler yapılacaksa CLLocationManager kullanılır.
    var locationManager = CLLocationManager()
    var chosenLatitude = Double()
    var chosenLongitude = Double()
//   selectedTitle boşsa kullanıcı yeni bir yer eklemeye çalışıyor , eğer doluysa kaydettiği veriye tıklamaya çalışıyor.
    var selectedTitle = ""
    var selectedtitleID : UUID?
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
//        Konumun verisi ne kadar detaylı bulunacak..
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//     Kullanıcıdan sadece uygulamayı kullanırken konumu kullanma izni
        locationManager.requestWhenInUseAuthorization()
//        Kullanıcının konumunu almaya başlayalım.
        locationManager.startUpdatingLocation()
//        Kullanıcı bir lokasyonu seçmek isterse üzerine basılı tutsun.
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
//        Kullanıcı seçtiği lokasyona 3 saniye basılı tutsun.
        gestureRecognizer.minimumPressDuration = 3
//        Map'e ekle.
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedTitle != "" {
//            Core Data-Kullanıcı kaydettiği veriye bakacak.
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedtitleID?.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@",idString!)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchRequest)
                
                if results.count > 0{
                    for result in results as! [NSManagedObject]{
                        if let title = result.value(forKey: "title") as? String{
                            annotationTitle = title
                            if let subTitle = result.value(forKey: "subtitle") as? String{
                            annotationSubtitle = subTitle
                        }
                            if let latitude = result.value(forKey: "latitude") as? Double{
                            annotationLatitude = latitude
                        }
                            if let longitude = result.value(forKey: "longitude") as? Double{
                                annotationLongitude = longitude
                        }
//                           Kayıtlı lokasyon açıldığındaki PIN'i oluşturma.
                            let annotation = MKPointAnnotation()
                            annotation.title = annotationTitle
                            annotation.subtitle = annotationSubtitle
                            let coordinate = CLLocationCoordinate2DMake(annotationLatitude, annotationLongitude)
                            annotation.coordinate = coordinate
                            
                            mapView.addAnnotation(annotation)
                            nameText.text = annotationTitle
                            commentText.text = annotationSubtitle
//                          Kullanıcı kayıtlı bir yere bakarken kendi konumunu güncellemeyi bırak.
                            locationManager.stopUpdatingLocation()
//                          Kayıtlı bir yere bakarken zoom yapılmasını sağla.
                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                            let region = MKCoordinateRegion(center: coordinate, span: span)
                            mapView.setRegion(region, animated: true)
                        }
                    }
                }
            
            }catch{
                print("error")
            }
        }else{
            
        }
    }
//    Bu fonksiyonun içinde gestureRecognizer'ın değişik özelliklerini kullanabilmek için parantez içinde bunu kullandık.
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer) {
//        Eğer dokunma işlemi başladıysa(3 saniye)
        if gestureRecognizer.state == .began {
//            Dokunulan nokta
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
//            Dokunulan noktanın koordinatları
            let touchedCoordinats = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            chosenLatitude = touchedCoordinats.latitude
            chosenLongitude = touchedCoordinats.longitude
//            Lokasyon seçildiğinde oluşan PIN(kırmızı nokta)
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinats
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
        }
        
    }
//    Bu fonksiyon güncellenen lokasyonları [CLLocation] şeklinde bir dizi içerisinde veriyor.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedTitle == ""{
        let location = CLLocationCoordinate2DMake(locations[0].coordinate.latitude, locations[0].coordinate.longitude)
//        Zoom seviyesi(sayı ne kadar küçük olursa o kadar zoomlu açılır map)
        let span = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
//
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        }else{
            
        }
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        Kullanıcının yerini PIN ile göstermemek için if'li kodu yazalım.
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
// info'nun rengi
            pinView?.tintColor = UIColor.blue
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else{
            pinView?.annotation = annotation
        }
        
        return pinView
        
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedTitle != ""{
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarks, error in
//                closure
                
                if let placemark = placemarks{
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
            
        }
    }
    @IBAction func saveButton(_ sender: Any) {
//   Appdelegate içindeki context'e ulaşalım.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
//        Kullanıcının kaydetmek istediği verileri koyacağımız yer.
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        newPlace.setValue(nameText.text, forKey: "title")
        newPlace.setValue(commentText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        do{
            try context.save()
            print("success")
        }catch{
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
        
        
    }
    

}

