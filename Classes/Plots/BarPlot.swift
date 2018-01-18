
import UIKit

open class BarPlot : Plot {
    
    // Customisation
    // #############
    
    /// The width of an individual bar on the graph.
    open var barWidth: CGFloat = 25;
    /// The actual colour of the bar.
    open var barColor: UIColor = UIColor.gray
    /// The width of the outline of the bar
    open var barLineWidth: CGFloat = 1
    /// The colour of the bar outline
    open var barLineColor: UIColor = UIColor.darkGray
    /// Whether the bars should be drawn with rounded corners
    open var shouldRoundBarCorners: Bool = false
    /// Whether the bar should draw text value.
    open var shouldDisplayValue: Bool = false
    /// to receive drawable text value
    open var dataSource: ScrollableGraphViewDataSource?
    
    // Private State
    // #############
    
    private var barLayer: BarDrawingLayer?
    
    public init(identifier: String) {
        super.init()
        self.identifier = identifier
    }
    
    override func layers(forViewport viewport: CGRect) -> [ScrollableGraphViewDrawingLayer?] {
        createLayers(viewport: viewport)
        return [barLayer]
    }
    
    internal override func graphValue(forIndex index: Int) -> String? {
        return dataSource?.auxiliaryValue(forPlot: self, atIndex: index)
    }
    internal override func graphValueFont(forIndex index: Int) -> UIFont? {
        return dataSource?.auxiliaryValueFont(forPlot: self, atIndex: index)
    }
    internal override func graphValueTextcolorAtOutSide(forIndex index: Int) -> UIColor? {
        return dataSource?.auxiliaryValueTextColorAtOutSide(forPlot: self, atIndex: index)
    }
    internal override func graphValueTextcolorAtInSide(forIndex index: Int) -> UIColor? {
        return dataSource?.auxiliaryValueTextColorAtInSide(forPlot: self, atIndex: index)
    }
    internal override func customBarWidth(forIndex index: Int) -> CGFloat? {
        return dataSource?.auxiliarycustomBarWidthValue(forPlot: self, atIndex: index)
    }
    internal override func customBarFillColor(forIndex index: Int) -> UIColor? {
        return dataSource?.auxiliarycustomBarBarFillColorValue(forPlot: self, atIndex: index)
    }
    internal override func graphValueLabelTransform(forIndex index: Int) -> CATransform3D? {
        return dataSource?.labelTransform(atIndex: index)
    }
    
    private func createLayers(viewport: CGRect) {
        barLayer = BarDrawingLayer(
            frame: viewport,
            barWidth: barWidth,
            barColor: barColor,
            barLineWidth: barLineWidth,
            barLineColor: barLineColor,
            shouldRoundCorners: shouldRoundBarCorners,
            shouldDisplayValue: shouldDisplayValue)

        barLayer?.owner = self
    }
}
