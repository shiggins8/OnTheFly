//
//  ReportComposer.swift
//  On The Fly
//
//  Created by Scott Higgins on 3/17/17.
//  Copyright © 2017 ScottieH. All rights reserved.
//

import UIKit

class ReportComposer: NSObject {
    
    let pathToReportHTMLTemplate = Bundle.main.path(forResource: "report_template", ofType: "html")
    
    var flight: Flight!
    
    var plane: Plane!
    
    var pdfFilename: String!
    
    
    override init() {
        super.init()
    }
    
    
    func renderReport(imagePath: String) -> String! {
        
        let timeStamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        
        do {
            // Load the invoice HTML template code into a String variable.
            var HTMLContent = try String(contentsOfFile: pathToReportHTMLTemplate!)
            
            // Replace all the placeholders with real values.
            // The timestamp.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#TIME_STAMP#", with: timeStamp)
            
            // Flight itenerary.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#FLIGHT_ITENERARY#", with: flight.getFlightItenerary())
            
            // The graph itself.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#COG_GRAPH#", with: "file://" + imagePath)
            
            // Tail number.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#TAIL_NUMBER#", with: plane.tailNumber)
            
            // Base empty weight.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#BEW#", with: "\(plane.emptyWeight)")
            
            // Total passenger weight.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#TOTAL_PASS_WEIGHT#", with: "\(flight.calcTotalPaxWeight())")
            
            // Cargo holds.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#FRONT_CARGO_HOLD#", with: "\(flight.frontBaggageWeight)")
            HTMLContent = HTMLContent.replacingOccurrences(of: "#AFT_CARGO_HOLD#", with: "\(flight.aftBaggageWeight)")
            
            // Fuel tank.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#FUEL_TANK#", with: "\(flight.startFuel)")
            
            // Fuel burn.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#FUEL_BURN#", with: "\(flight.fuelFlow)")
            
            // Taxi fuel usage.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#TAXI_BURN#", with: "\(flight.taxiFuelBurn)")
            
            // Max takeoff weight.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#MAX_TO_WEIGHT#", with: "\(plane.maxTakeoffWeight)")
            
            // Zero fuel weight.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#ZERO_FUEL_WEIGHT#", with: "\(flight.calcZeroFuelWeight(plane: plane))")
            
            //CoG Data Table
            var takeoffLimits = self.flight.calcTakeoffLimits(plane: self.plane)
            if takeoffLimits.count != 2 {
                takeoffLimits = [0.0, 0.0]
            }
            var landingLimits = self.flight.calcLandingLimits(plane: self.plane)
            if landingLimits.count != 2 {
                landingLimits = [0.0, 0.0]
            }
            
            HTMLContent = HTMLContent.replacingOccurrences(of: "#TAKEOFF_WEIGHT#", with: "\(flight.calcTakeoffWeight(plane: plane))")
            
            HTMLContent = HTMLContent.replacingOccurrences(of: "#TAKEOFF_FWD_LIMIT#", with: "\(takeoffLimits[0])")
            
            HTMLContent = HTMLContent.replacingOccurrences(of: "#TAKEOFF_COG#", with: "\(flight.calcTakeoffCenterOfGravity(plane: plane).roundTo(places: 2))")
            
            HTMLContent = HTMLContent.replacingOccurrences(of: "#TAKEOFF_AFT_LIMIT#", with: "\(takeoffLimits[1])")
            
            HTMLContent = HTMLContent.replacingOccurrences(of: "#LANDING_WEIGHT#", with: "\(flight.calcLandingWeight(plane: plane))")
            
            HTMLContent = HTMLContent.replacingOccurrences(of: "#LANDING_FWD_LIMIT#", with: "\(landingLimits[0])")
            
            HTMLContent = HTMLContent.replacingOccurrences(of: "#LANDING_COG#", with: "\(flight.calcLandingCenterOfGravity(plane: plane).roundTo(places: 2))")
            
            HTMLContent = HTMLContent.replacingOccurrences(of: "#LANDING_AFT_LIMIT#", with: "\(landingLimits[1])")
            
            // The HTML code is ready.
            return HTMLContent
            
        }
        catch {
            print("Unable to open and use HTML template files.")
        }
        
        return nil
    }
    
    
    func exportHTMLContentToPDF(webView: UIWebView) {
        let printPageRenderer = CustomPrintPageRenderer()

        printPageRenderer.addPrintFormatter(webView.viewPrintFormatter(), startingAtPageAt: 0)
        
        let pdfData = drawPDFUsingPrintPageRenderer(printPageRenderer: printPageRenderer)
        
        pdfFilename = "\((UIApplication.shared.delegate as! AppDelegate).getDocDir())/Report\(1).pdf"
        pdfData?.write(toFile: pdfFilename, atomically: true)
        
        print(pdfFilename)
    }
    
    
    func drawPDFUsingPrintPageRenderer(printPageRenderer: UIPrintPageRenderer) -> NSData! {
        let data = NSMutableData()
        
        UIGraphicsBeginPDFContextToData(data, CGRect.zero, nil)
        
        UIGraphicsBeginPDFPage()
        
        printPageRenderer.drawPage(at: 0, in: UIGraphicsGetPDFContextBounds())
        
        UIGraphicsEndPDFContext()
        
        return data
    }
    
}
