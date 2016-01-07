//
//  ViewController.swift
//  ArcGisTest
//
//  Created by Josh Lay on 6/01/2016.
//  Copyright © 2016 Agworld. All rights reserved.
//

import UIKit
import ArcGIS

class ViewController: UIViewController {
    @IBOutlet weak var mapView: AGSMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let url = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer") else {
            return
        }

        let serviceLayer = AGSTiledMapServiceLayer(URL: url)
        mapView.addMapLayer(serviceLayer, withName: "Basemap Tiled Layer")

        let layer = AGSGraphicsLayer.graphicsLayer() as! AGSGraphicsLayer

        let myMarkerSymbol = AGSSimpleMarkerSymbol.simpleMarkerSymbolWithColor(UIColor.greenColor()) as! AGSSimpleMarkerSymbol
        layer.renderer = AGSSimpleRenderer(symbol: myMarkerSymbol)
        mapView.addMapLayer(layer, withName: "Graphics Layer")
        populateGraphicsLayer(layer)
    }

    private func populateGraphicsLayer(layer: AGSGraphicsLayer) {
        let baseLat = -31.9413524
        let baseLng = 115.8394953

        var markers: Array<AGSGeometry> = [AGSGeometry]()
        for i in 1...10 {
            let lat = baseLat + Double(Double(i) / 100.0)
            let lng = baseLng

            let myMarkerPoint = AGSPoint(location: CLLocation(latitude: lat, longitude: lng))

            let ge = AGSGeometryEngine.defaultGeometryEngine()
            let reprojectedPoint = ge.projectGeometry(myMarkerPoint, toSpatialReference: AGSSpatialReference.webMercatorSpatialReference())

            let myGraphic = AGSGraphic(geometry: reprojectedPoint, symbol: nil, attributes: nil)

            layer.addGraphic(myGraphic)

            markers.append(reprojectedPoint)
        }

        mapView.zoomToGeometry(markers.last, withPadding: 1000, animated: true)
    }
}

