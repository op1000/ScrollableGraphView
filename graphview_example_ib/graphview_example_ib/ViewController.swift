//
//  ViewController.swift
//  graphview_example_ib
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var graphView: ScrollableGraphView!
    
    var numberOfItems = 30
    lazy var plotOneData: [Double] = self.generateRandomData(self.numberOfItems, max: 100, shouldIncludeOutliers: true)
    lazy var plotTwoData: [Double] = self.generateRandomData(self.numberOfItems, max: 80, shouldIncludeOutliers: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        graphView.dataSource = self
        setupGraph(graphView: graphView)
    }
    
    // ScrollableGraphViewDataSource
    // #############################
    
    func value(forPlot plot: Plot, atIndex pointIndex: Int) -> Double {
        switch(plot.identifier) {
        case "one":
            return plotOneData[pointIndex]
        case "two":
            return plotTwoData[pointIndex]
        default:
            return 0
        }
    }
    
    func label(atIndex pointIndex: Int) -> String {
        return "FEB \(pointIndex)"
    }
    
    func numberOfPoints() -> Int {
        return numberOfItems
    }
    
    // Helper Functions
    // ################
    
    // When using Interface Builder, only add the plots and reference lines in code.
    func setupGraph(graphView: ScrollableGraphView) {
        
        // Setup the first line plot.
        let blueLinePlot = LinePlot(identifier: "one")
        
        blueLinePlot.lineWidth = 5
        blueLinePlot.lineColor = UIColor.colorFromHex(hexString: "#16aafc")
        blueLinePlot.lineStyle = ScrollableGraphViewLineStyle.smooth
        
        blueLinePlot.shouldFill = false
        blueLinePlot.fillType = ScrollableGraphViewFillType.solid
        blueLinePlot.fillColor = UIColor.colorFromHex(hexString: "#16aafc").withAlphaComponent(0.5)
        
        blueLinePlot.adaptAnimationType = ScrollableGraphViewAnimationType.elastic
        
        // Setup the second line plot.
        let orangeLinePlot = LinePlot(identifier: "two")
        
        orangeLinePlot.lineWidth = 5
        orangeLinePlot.lineColor = UIColor.colorFromHex(hexString: "#ff7d78")
        orangeLinePlot.lineStyle = ScrollableGraphViewLineStyle.smooth
        
        orangeLinePlot.shouldFill = false
        orangeLinePlot.fillType = ScrollableGraphViewFillType.solid
        orangeLinePlot.fillColor = UIColor.colorFromHex(hexString: "#ff7d78").withAlphaComponent(0.5)
        
        orangeLinePlot.adaptAnimationType = ScrollableGraphViewAnimationType.elastic
        
        // Customise the reference lines.
        let referenceLines = ReferenceLines()
        
        referenceLines.referenceLineLabelFont = UIFont.boldSystemFont(ofSize: 8)
        referenceLines.referenceLineColor = UIColor.black.withAlphaComponent(0.2)
        referenceLines.referenceLineLabelColor = UIColor.black
        
        referenceLines.dataPointLabelColor = UIColor.black.withAlphaComponent(1)
        
        // All other graph customisation is done in Interface Builder, 
        // e.g, the background colour would be set in interface builder rather than in code.
        // graphView.backgroundFillColor = UIColor.colorFromHex(hexString: "#333333")
        
        // Add everything to the graph.
        graphView.addReferenceLines(referenceLines: referenceLines)
        graphView.addPlot(plot: blueLinePlot)
        graphView.addPlot(plot: orangeLinePlot)
    }
    
    private func generateRandomData(_ numberOfItems: Int, max: Double, shouldIncludeOutliers: Bool = true) -> [Double] {
        var data = [Double]()
        for _ in 0 ..< numberOfItems {
            var randomNumber = Double(arc4random()).truncatingRemainder(dividingBy: max)
            
            if(shouldIncludeOutliers) {
                if(arc4random() % 100 < 10) {
                    randomNumber *= 3
                }
            }
            
            data.append(randomNumber)
        }
        return data
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension ViewController: ScrollableGraphViewDataSource {
    
    func auxiliaryValue(forPlot plot: Plot, atIndex pointIndex: Int) -> String? {
        return nil
    }
    
    func auxiliaryValueFont(forPlot plot: Plot, atIndex pointIndex: Int) -> UIFont? {
        return nil
    }
    
    func auxiliaryValueTextColorAtOutSide(forPlot plot: Plot, atIndex pointIndex: Int) -> UIColor? {
        return nil
    }
    
    func auxiliaryValueTextColorAtInSide(forPlot plot: Plot, atIndex pointIndex: Int) -> UIColor? {
        return nil
    }
    
    func auxiliaryValueTextShouldPlaceAtOutSide(forPlot plot: Plot, atIndex pointIndex: Int) -> Bool? {
        return false
    }
    
    func auxiliaryValueShouldPlaceAtInSide(forPlot plot: Plot, atIndex pointIndex: Int) -> Bool? {
        return false
    }
    
    func auxiliaryValueLocationOffset(forPlot plot: Plot, atIndex pointIndex: Int) -> CGPoint? {
        return nil
    }
    
    func auxiliarycustomBarWidthValue(forPlot plot: Plot, atIndex pointIndex: Int) -> CGFloat? {
        return nil
    }
    
    func auxiliarycustomBarBarFillColorValue(forPlot plot: Plot, atIndex pointIndex: Int) -> UIColor? {
        return nil
    }
    
    func labelTransform(atIndex pointIndex: Int) -> CATransform3D? {
        return nil
    }
    
    func labelCustomText(forGraph graph: ReferenceLines, atIndex pointIndex: Int) -> String? {
        return nil
    }
}
