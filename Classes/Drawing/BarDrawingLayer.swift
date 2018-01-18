
import UIKit

// MARK: Drawing the bars
internal class BarDrawingLayer: ScrollableGraphViewDrawingLayer {
    
    private var barPlotFrame: [CGPoint]?
    private var barPath = UIBezierPath()
    private var barWidth: CGFloat = 4
    private var shouldRoundCorners = false
    private var internalSubLayers: NSMutableArray = NSMutableArray()
    
    init(frame: CGRect,
         barWidth: CGFloat,
         barColor: UIColor,
         barLineWidth: CGFloat,
         barLineColor: UIColor,
         shouldRoundCorners: Bool,
         shouldDisplayValue: Bool)
    {
        super.init(viewportWidth: frame.size.width, viewportHeight: frame.size.height)
        
        self.barWidth = barWidth
        self.lineWidth = barLineWidth
        self.strokeColor = barLineColor.cgColor
        self.fillColor = barColor.cgColor
        self.shouldRoundCorners = shouldRoundCorners
        
        self.lineJoin = lineJoin
        self.lineCap = lineCap
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // We can only move forward if we can get the data we need from the delegate.
            guard let activePointsInterval = self.owner?.graphViewDrawingDelegate?.intervalForActivePoints()
                else {
                    return
            }
            
            self.internalSubLayers.enumerateObjects({ (object, index, stop) in
                if let layer: CATextLayer = object as? CATextLayer {
                    layer.removeFromSuperlayer()
                }
            })
            
            if shouldDisplayValue == true {
                for i in activePointsInterval {
                    
                    var location = CGPoint.zero
                    
                    if let pointLocation = self.owner?.graphPoint(forIndex: i).location {
                        location = pointLocation
                    }
                    let valueString: String? = self.owner?.graphValue(forIndex: i);
                    let valueFont: UIFont? = self.owner?.graphValueFont(forIndex: i);
                    let valueColorAtOutSide: UIColor? = self.owner?.graphValueTextcolorAtOutSide(forIndex: i)
                    let valueColorAtInSide: UIColor? = self.owner?.graphValueTextcolorAtInSide(forIndex: i)
                    
                    let label = CATextLayer()
                    if valueFont != nil {
                        label.font = valueFont
                    }
                    else {
                        label.font = UIFont.systemFont(ofSize: 10.0)
                    }
                    if valueColorAtOutSide != nil {
                        label.foregroundColor = valueColorAtOutSide?.cgColor
                    }
                    else {
                        label.foregroundColor = UIColor.white.cgColor
                    }
                    
                    label.fontSize = 10.0
                    label.string = valueString
                    var labelSize : CGSize = label.preferredFrameSize()
                    let contatinsResult = valueString?.contains("(")
                    if contatinsResult != nil {
                        let transform: CATransform3D? = self.owner?.graphValueLabelTransform(forIndex: i)
                        if transform != nil {
                            let plotHeight: CGPoint = self.barPlotFrame![i]
                            debugPrint("location.y + labelSize.height = \(location.y + labelSize.height), plotHeight = \(NSStringFromCGPoint(plotHeight))")
                            if location.y + labelSize.height > plotHeight.x {
                                // 밖에 배치
                                if (contatinsResult)! {
                                    label.frame = CGRect.init(x: location.x - (labelSize.width / 2.0), y: location.y - labelSize.height - 35.0, width: labelSize.width, height: labelSize.height)
                                }
                                else {
                                    label.frame = CGRect.init(x: location.x - (labelSize.width / 2.0), y: location.y - labelSize.height - 25.0, width: labelSize.width, height: labelSize.height)
                                }
                            }
                            else {
                                // 안에 배치
                                if (contatinsResult)! {
                                    label.frame = CGRect.init(x: location.x - (labelSize.width / 2.0), y: location.y + labelSize.height + 35.0, width: labelSize.width, height: labelSize.height)
                                }
                                else {
                                    label.frame = CGRect.init(x: location.x - (labelSize.width / 2.0), y: location.y + labelSize.height + 10.0, width: labelSize.width, height: labelSize.height)
                                }
                                label.foregroundColor = valueColorAtInSide?.cgColor
                            }
                            
                            label.alignmentMode = "center"
                            label.contentsScale = UIScreen.main.scale
                            
                            label.transform = transform!
                        }
                        else {
                            label.alignmentMode = "center"
                            label.contentsScale = UIScreen.main.scale
                            
                            if labelSize.width < barWidth {
                                labelSize.width = barWidth
                            }
                            
                            label.frame = CGRect.init(x: location.x - (labelSize.width / 2.0), y: location.y - labelSize.height - 3.0, width: labelSize.width, height: labelSize.height)
                            label.foregroundColor = valueColorAtInSide?.cgColor
                        }
                        
                        self.addSublayer(label)
                        self.internalSubLayers.add(label)
                    }
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createBarPath(centre: CGPoint, atIndex index: Int) -> UIBezierPath {
        
        var barWidthToUse: CGFloat = self.barWidth
        let customBarWidth: CGFloat? = self.owner?.customBarWidth(forIndex: index);
        var barWidthOffset: CGFloat = self.barWidth / 2
        if customBarWidth != nil {
            barWidthOffset = customBarWidth! / 2
            barWidthToUse = customBarWidth!
        }
        
        let origin = CGPoint(x: centre.x - barWidthOffset, y: centre.y)
        let size = CGSize(width: barWidthToUse, height: zeroYPosition - centre.y)
        let rect = CGRect(origin: origin, size: size)
        
        let barPath: UIBezierPath = {
            if shouldRoundCorners {
                return UIBezierPath(roundedRect: rect, cornerRadius: barWidthOffset)
            } else {
                return UIBezierPath(rect: rect)
            }
        }()
        
        return barPath
    }
    
    private func calculateBarRect(centre: CGPoint, atIndex index: Int) -> CGRect {
        var barWidthToUse: CGFloat = self.barWidth
        let customBarWidth: CGFloat? = self.owner?.customBarWidth(forIndex: index);
        var barWidthOffset: CGFloat = self.barWidth / 2
        if customBarWidth != nil {
            barWidthOffset = customBarWidth! / 2
            barWidthToUse = customBarWidth!
        }
        
        let origin = CGPoint(x: centre.x - barWidthOffset, y: centre.y)
        let size = CGSize(width: barWidthToUse, height: zeroYPosition - centre.y)
        let rect = CGRect(origin: origin, size: size)
        return rect
    }
    
    private func createPath () -> UIBezierPath {
        
        barPath.removeAllPoints()
        
        // We can only move forward if we can get the data we need from the delegate.
        guard let
            activePointsInterval = self.owner?.graphViewDrawingDelegate?.intervalForActivePoints()
            else {
                return barPath
        }
        
        self.internalSubLayers.enumerateObjects({ (object, index, stop) in
            if let layer: CALayer = object as? CALayer {
                layer.removeFromSuperlayer()
            }
        })
        
        var realTimePlotFrame: [CGPoint] = [CGPoint]()
        for i in activePointsInterval {
            
            var location = CGPoint.zero
            
            if let pointLocation = owner?.graphPoint(forIndex: i).location {
                location = pointLocation
                //debugPrint("pointLocation = \(pointLocation)")
                realTimePlotFrame.append(pointLocation)
            }
            let pointPath = createBarPath(centre: location, atIndex: i)
            
            let customFillColor: UIColor? = self.owner?.customBarFillColor(forIndex: i);
            if customFillColor != nil {
                let subLayer: CALayer = CALayer()
                subLayer.backgroundColor = customFillColor?.cgColor
                subLayer.frame = calculateBarRect(centre: location, atIndex: i)
                
                self.addSublayer(subLayer)
                self.internalSubLayers.add(subLayer)
            }
            
            barPath.append(pointPath)
        }
        self.barPlotFrame = realTimePlotFrame
        
        return barPath
    }
    
    override func updatePath() {
        
        self.path = createPath ().cgPath
    }
}
