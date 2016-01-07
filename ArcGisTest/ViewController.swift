//
//  ViewController.swift
//  ArcGisTest
//
//  Created by Josh Lay on 6/01/2016.
//  Copyright © 2016 Agworld. All rights reserved.
//

import UIKit
import ArcGIS

class ViewController: UIViewController, AGSMapViewTouchDelegate, AGSLayerCalloutDelegate {
    @IBOutlet weak var mapView: AGSMapView!

    private let graphicsLayerIdentifier = "Graphics Layer"

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let url = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer") else {
            return
        }

        mapView.touchDelegate = self

        let serviceLayer = AGSTiledMapServiceLayer(URL: url)
        mapView.addMapLayer(serviceLayer, withName: "Basemap Tiled Layer")

        let layer = AGSGraphicsLayer.graphicsLayer() as! AGSGraphicsLayer
        layer.calloutDelegate = self

        let myMarkerSymbol = AGSSimpleMarkerSymbol.simpleMarkerSymbolWithColor(UIColor.greenColor()) as! AGSSimpleMarkerSymbol
        layer.renderer = AGSSimpleRenderer(symbol: myMarkerSymbol)
        mapView.addMapLayer(layer, withName: graphicsLayerIdentifier)
        populateGraphicsLayer(layer)
    }

    private func populateGraphicsLayer(layer: AGSGraphicsLayer) {
        let baseLat = -31.9413524
        let baseLng = 115.8394953

        let envelope: AGSMutableEnvelope = AGSMutableEnvelope(spatialReference: AGSSpatialReference.webMercatorSpatialReference())
        let names = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
        for i in 0...9 {
            let lat = baseLat + Double(Double(i) / 100.0)
            let lng = baseLng

            let myMarkerPoint = AGSPoint(location: CLLocation(latitude: lat, longitude: lng))

            let ge = AGSGeometryEngine.defaultGeometryEngine()
            let reprojectedPoint = ge.projectGeometry(myMarkerPoint, toSpatialReference: AGSSpatialReference.webMercatorSpatialReference())

            let attributes = [
                "name": names[i],
                "id": NSNumber(integer: i)
            ]
            let myGraphic = AGSGraphic(geometry: reprojectedPoint, symbol: nil, attributes: attributes)

            layer.addGraphic(myGraphic)

            envelope.unionWithEnvelope(reprojectedPoint.envelope)
        }

        mapView.zoomToEnvelope(envelope, animated: true)
    }

    //MARK: AGSMapViewTouchDelegate
    func mapView(mapView: AGSMapView!, didClickAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
        guard let graphicLayerFeatures = features[graphicsLayerIdentifier] as? [AGSFeature] where features.keys.count > 0 else {
            return
        }

        for feature in graphicLayerFeatures {
            if feature.geometry is AGSPoint {
                if let id = feature.attributeForKey("id") as? NSNumber {
                    NSLog("Tapped Point: %@", id)
                }
            }
        }
    }

    //MARK: AGSCalloutDelegate
    func callout(callout: AGSCallout!, willShowForFeature feature: AGSFeature!, layer: AGSLayer!, mapPoint: AGSPoint!) -> Bool {
        if feature.geometry is AGSPoint {
            mapView.callout.title = feature.attributeAsStringForKey("name")
            mapView.callout.detail = feature.attributeAsStringForKey("id")

            return true
        }

        return false
    }
}

