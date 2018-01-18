
import UIKit

open class DotPlot : Plot {
    
    // Customisation
    // #############
    
    /// The shape to draw for each data point.
    open var dataPointType = ScrollableGraphViewDataPointType.circle
    /// The size of the shape to draw for each data point.
    open var dataPointSize: CGFloat = 5
    /// The colour with which to fill the shape.
    open var dataPointFillColor: UIColor = UIColor.black
    /// If dataPointType is set to .Custom then you,can provide a closure to create any kind of shape you would like to be displayed instead of just a circle or square. The closure takes a CGPoint which is the centre of the shape and it should return a complete UIBezierPath.
    open var customDataPointPath: ((_ centre: CGPoint) -> UIBezierPath)?
    /// to receive drawable text value
    open var dataSource: ScrollableGraphViewDataSource?
    
    // Private State
    // #############
    
    private var dataPointLayer: DotDrawingLayer?
    
    public init(identifier: String) {
        super.init()
        self.identifier = identifier
    }
    
    override func layers(forViewport viewport: CGRect) -> [ScrollableGraphViewDrawingLayer?] {
        createLayers(viewport: viewport)
        return [dataPointLayer]
    }
    
    internal override func graphValue(forIndex index: Int) -> String? {
        return dataSource?.auxiliaryValue(forPlot: self, atIndex: index)
    }
    internal override func graphValueFont(forIndex index: Int) -> UIFont? {
        return dataSource?.auxiliaryValueFont(forPlot: self, atIndex: index)
    }
    internal override func graphValueShouldPlaceAtOutSide(forIndex index: Int) -> Bool? {
        return dataSource?.auxiliaryValueTextShouldPlaceAtOutSide(forPlot: self, atIndex: index)
    }
    internal override func graphValueShouldPlaceAtInSide(forIndex index: Int) -> Bool? {
        return dataSource?.auxiliaryValueShouldPlaceAtInSide(forPlot: self, atIndex: index)
    }
    internal override func graphValueLocationOffset(forIndex index: Int) -> CGPoint? {
        return dataSource?.auxiliaryValueLocationOffset(forPlot: self, atIndex: index)
    }
    
    private func createLayers(viewport: CGRect) {
        dataPointLayer = DotDrawingLayer(
            frame: viewport,
            fillColor: dataPointFillColor,
            dataPointType: dataPointType,
            dataPointSize: dataPointSize,
            customDataPointPath: customDataPointPath)

        dataPointLayer?.owner = self
    }
}

@objc public enum ScrollableGraphViewDataPointType : Int {
    case circle
    case square
    case custom
}
