
import UIKit

public protocol ScrollableGraphViewDataSource {
    func value(forPlot plot: Plot, atIndex pointIndex: Int) -> Double
    func label(atIndex pointIndex: Int) -> String
    func numberOfPoints() -> Int // This now forces the same number of points in each plot.
    
    func auxiliaryValue(forPlot plot: Plot, atIndex pointIndex: Int) -> String?
    func auxiliaryValueFont(forPlot plot: Plot, atIndex pointIndex: Int) -> UIFont?
    func auxiliaryValueTextColorAtOutSide(forPlot plot: Plot, atIndex pointIndex: Int) -> UIColor?
    func auxiliaryValueTextColorAtInSide(forPlot plot: Plot, atIndex pointIndex: Int) -> UIColor?
    func auxiliaryValueTextShouldPlaceAtOutSide(forPlot plot: Plot, atIndex pointIndex: Int) -> Bool?
    func auxiliaryValueShouldPlaceAtInSide(forPlot plot: Plot, atIndex pointIndex: Int) -> Bool?
    func auxiliaryValueLocationOffset(forPlot plot: Plot, atIndex pointIndex: Int) -> CGPoint?
    
    func auxiliarycustomBarWidthValue(forPlot plot: Plot, atIndex pointIndex: Int) -> CGFloat?
    func auxiliarycustomBarBarFillColorValue(forPlot plot: Plot, atIndex pointIndex: Int) -> UIColor?
    
    func labelTransform(atIndex pointIndex: Int) -> CATransform3D?
    func labelCustomText(forGraph graph: ReferenceLines, atIndex pointIndex: Int) -> String?
}
