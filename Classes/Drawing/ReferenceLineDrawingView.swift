
import UIKit

internal class ReferenceLineDrawingView : UIView {
    
    var settings: ReferenceLines = ReferenceLines()
    
    var dataSource: ScrollableGraphViewDataSource?
    
    // PRIVATE PROPERTIES
    // ##################
    
    private var labelMargin: CGFloat = 4
    private var leftLabelInset: CGFloat = 10
    private var rightLabelInset: CGFloat = 10
    
    // Store information about the ScrollableGraphView
    private var currentRange: (min: Double, max: Double) = (0,100)
    private var topMargin: CGFloat = 10
    private var bottomMargin: CGFloat = 10
    
    private var lineWidth: CGFloat {
        get {
            return self.bounds.width
        }
    }
    
    private var units: String {
        get {
            if let units = self.settings.referenceLineUnits {
                return " \(units)"
            } else {
                return ""
            }
        }
    }
    
    // Layers
    private var labels = [UILabel]()
    private let referenceLineLayer = CAShapeLayer()
    private let referenceLinePath = UIBezierPath()
    private var referenceRightGuardLineLayer: CAShapeLayer?
    private var referenceBottomGuardLineLayer: CAShapeLayer?
    private var leftGuardGuides: NSMutableArray = NSMutableArray()
    private var leftGuardLongestLabelLineStartX: CGFloat = 0.0;
    
    init(frame: CGRect, topMargin: CGFloat, bottomMargin: CGFloat, referenceLineColor: UIColor, referenceLineThickness: CGFloat, referenceLineSettings: ReferenceLines) {
        super.init(frame: frame)
        
        self.topMargin = topMargin
        self.bottomMargin = bottomMargin
        
        // The reference line layer draws the reference lines and we handle the labels elsewhere.
        self.referenceLineLayer.frame = self.frame
        self.referenceLineLayer.strokeColor = referenceLineColor.cgColor
        self.referenceLineLayer.lineWidth = referenceLineThickness
        if referenceLineSettings.referenceLineStyle == ScrollableGraphViewReferenceLineStyle.dashed {
            self.referenceLineLayer.lineDashPattern = NSArray(array: [NSNumber(value: 8), NSNumber(value: 4)]) as? [NSNumber]
        }
        
        self.settings = referenceLineSettings
        
        self.layer.addSublayer(referenceLineLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLabel(at position: CGPoint, withText text: String) -> UILabel {
        let frame = CGRect(x: position.x, y: position.y, width: 0, height: 0)
        let label = UILabel(frame: frame)
        
        return label
    }
    
    private func createReferenceLinesPath() -> UIBezierPath {
        
        referenceLinePath.removeAllPoints()
        for label in labels {
            label.removeFromSuperview()
        }
        labels.removeAll()
        
        if (self.settings.includeMinMax) {
            let maxLineStart = CGPoint(x: 0, y: topMargin)
            let maxLineEnd = CGPoint(x: lineWidth, y: topMargin)
            
            let minLineStart = CGPoint(x: 0, y: self.bounds.height - bottomMargin)
            let minLineEnd = CGPoint(x: lineWidth, y: self.bounds.height - bottomMargin)
            
            let numberFormatter = referenceNumberFormatter()
            
            let maxString = numberFormatter.string(from: self.currentRange.max as NSNumber)! + units
            let minString = numberFormatter.string(from: self.currentRange.min as NSNumber)! + units
            
            addLine(withTag: maxString, from: maxLineStart, to: maxLineEnd, in: referenceLinePath, pointindex: 4)
            addLine(withTag: minString, from: minLineStart, to: minLineEnd, in: referenceLinePath, pointindex: 0)
        }
        
        let initialRect = CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y + topMargin, width: self.bounds.size.width, height: self.bounds.size.height - (topMargin + bottomMargin))
        
        switch(settings.positionType) {
        case .relative:
            createReferenceLines(in: initialRect, atRelativePositions: self.settings.relativePositions, forPath: referenceLinePath)
        case .absolute:
            createReferenceLines(in: initialRect, atAbsolutePositions: self.settings.absolutePositions, forPath: referenceLinePath)
        }
        
        return referenceLinePath
    }
    
    private func referenceNumberFormatter() -> NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = self.settings.referenceLineNumberStyle
        numberFormatter.minimumFractionDigits = self.settings.referenceLineNumberOfDecimalPlaces
        numberFormatter.maximumFractionDigits = self.settings.referenceLineNumberOfDecimalPlaces
        
        return numberFormatter
    }
    
    private func createReferenceLines(in rect: CGRect, atRelativePositions relativePositions: [Double], forPath path: UIBezierPath) {
        
        let height = rect.size.height
        var relativePositions = relativePositions
        
        // If we are including the min and max already need to make sure we don't redraw them.
        if(self.settings.includeMinMax) {
            relativePositions = relativePositions.filter({ (x:Double) -> Bool in
                return (x != 0 && x != 1)
            })
        }
        
        for relativePosition in relativePositions {
            
            let yPosition = height * CGFloat(1 - relativePosition)
            
            let lineStart = CGPoint(x: 0, y: rect.origin.y + yPosition)
            let lineEnd = CGPoint(x: lineStart.x + lineWidth, y: lineStart.y)
            
            let index: Int = relativePositions.index(of: relativePosition)! + 1
            createReferenceLineFrom(from: lineStart, to: lineEnd, in: path, pointindex: index)
        }
    }
    
    private func createReferenceLines(in rect: CGRect, atAbsolutePositions absolutePositions: [Double], forPath path: UIBezierPath) {
        
        for absolutePosition in absolutePositions {
            
            let yPosition = calculateYPositionForYAxisValue(value: absolutePosition)
            
            // don't need to add rect.origin.y to yPosition like we do for relativePositions,
            // as we calculate the position for the y axis value in the previous line,
            // this already takes into account margins, etc.
            let lineStart = CGPoint(x: 0, y: yPosition)
            let lineEnd = CGPoint(x: lineStart.x + lineWidth, y: lineStart.y)
            
            createReferenceLineFrom(from: lineStart, to: lineEnd, in: path, pointindex: Int.max)
        }
    }
    
    private func createReferenceLineFrom(from lineStart: CGPoint, to lineEnd: CGPoint, in path: UIBezierPath, pointindex index: Int) {
        if(self.settings.shouldAddLabelsToIntermediateReferenceLines) {
            
            let value = calculateYAxisValue(for: lineStart)
            let numberFormatter = referenceNumberFormatter()
            var valueString = numberFormatter.string(from: value as NSNumber)!
            
            if(self.settings.shouldAddUnitsToIntermediateReferenceLineLabels) {
                valueString += " \(units)"
            }
            
            addLine(withTag: valueString, from: lineStart, to: lineEnd, in: path, pointindex: index)
            
        } else {
            addLine(from: lineStart, to: lineEnd, in: path, pointindex: index)
        }
    }
    
    private func addLine(withTag tag: String, from: CGPoint, to: CGPoint, in path: UIBezierPath, pointindex index: Int) {
        
        let customLabelText: String? = self.dataSource?.labelCustomText(forGraph:self.settings, atIndex:index)
        var boundingSize: CGSize = CGSize()
        if customLabelText != nil {
            boundingSize = self.boundingSize(forText: customLabelText!)
        }
        else {
            boundingSize = self.boundingSize(forText: tag)
        }
        if customLabelText == "" {
            boundingSize = CGSize(width: 0.0, height: 0.0)
        }
        do {
            let transfrom :CATransform3D? = self.settings.referenceLineLabelTransForm
            if transfrom != nil {
                let affine: CGAffineTransform = CGAffineTransform(a: transfrom!.m11, b: transfrom!.m12, c: transfrom!.m21, d: transfrom!.m22, tx: transfrom!.m41, ty: transfrom!.m42)
                boundingSize = __CGSizeApplyAffineTransform(boundingSize, affine)
            }
        }
        let leftLabel = createLabel(withText: tag, pointindex: index)
        let rightLabel = createLabel(withText: tag, pointindex: index)
        
        // Left label gap.
        leftLabel.frame = CGRect(
            origin: CGPoint(x: from.x + leftLabelInset, y: from.y - (boundingSize.height / 2)),
            size: boundingSize)
        
        let leftLabelStart = CGPoint(x: leftLabel.frame.origin.x - labelMargin, y: to.y)
        let leftLabelEnd = CGPoint(x: (leftLabel.frame.origin.x + leftLabel.frame.size.width) + labelMargin, y: to.y)
        
        // Right label gap.
        rightLabel.frame = CGRect(
            origin: CGPoint(x: (from.x + self.frame.width) - rightLabelInset - boundingSize.width, y: from.y - (boundingSize.height / 2)),
            size: boundingSize)
        
        let rightLabelStart = CGPoint(x: rightLabel.frame.origin.x - labelMargin, y: to.y)
        let rightLabelEnd = CGPoint(x: (rightLabel.frame.origin.x + rightLabel.frame.size.width) + labelMargin, y: to.y)
        
        // Add the lines and tags depending on the settings for where we want them.
        var gaps = [(start: CGFloat, end: CGFloat)]()
        
        switch(self.settings.referenceLinePosition) {
            
        case .left:
            gaps.append((start: leftLabelStart.x, end: leftLabelEnd.x))
            self.addSubview(leftLabel)
            self.labels.append(leftLabel)
            
        case .right:
            gaps.append((start: rightLabelStart.x, end: rightLabelEnd.x))
            self.addSubview(rightLabel)
            self.labels.append(rightLabel)
            
            if settings.shouldDrawReferenceLineGuardLineForRightLabels == true && index == 0 {
                if settings.referenceLineStyle == ScrollableGraphViewReferenceLineStyle.solid {
                    path.move(to: CGPoint(x: rightLabelStart.x - 3.0, y: self.topMargin - 3.0))
                    path.addLine(to: CGPoint(x: rightLabelStart.x - 3.0, y: self.bounds.size.height - self.bottomMargin + 3.0))
                }
                else if settings.referenceLineStyle == ScrollableGraphViewReferenceLineStyle.dashed {
                    if settings.shouldDrawOutterReferenceLineAsSolidWhenReferenceLineStyleIsDashed == true && self.referenceRightGuardLineLayer == nil {
                        let borderLayer = CAShapeLayer()
                        borderLayer.name = "borderLayer"
                        borderLayer.frame = self.frame
                        borderLayer.fillColor = UIColor.clear.cgColor
                        borderLayer.strokeColor = self.referenceLineLayer.strokeColor
                        
                        let pathline = UIBezierPath()
                        pathline.move(to: CGPoint(x: rightLabelStart.x - 3.0, y: self.topMargin - 3.0))
                        pathline.addLine(to: CGPoint(x: rightLabelStart.x - 3.0, y: self.bounds.size.height - self.bottomMargin + 3.0))
                        
                        borderLayer.path = pathline.cgPath
                        self.referenceLineLayer.addSublayer(borderLayer)
                        self.referenceRightGuardLineLayer = borderLayer
                    }
                }
            }
            
        case .both:
            gaps.append((start: leftLabelStart.x, end: leftLabelEnd.x))
            gaps.append((start: rightLabelStart.x, end: rightLabelEnd.x))
            self.addSubview(leftLabel)
            self.addSubview(rightLabel)
            self.labels.append(leftLabel)
            self.labels.append(rightLabel)
            
            if settings.shouldDrawReferenceLineGuardLineForRightLabels == true {
                path.move(to: CGPoint(x: rightLabelStart.x - 3.0, y: rightLabelStart.y - 3.0))
                path.addLine(to: CGPoint(x: rightLabelStart.x - 3.0, y: self.bounds.size.height - self.bottomMargin + 3.0))
            }
        }
        
        addLine(from: from, to: to, withGaps: gaps, in: path, pointindex: index)
        
        do {
            leftLabel.frame = CGRect(x: leftLabel.frame.origin.x - 3.0,
                                     y: leftLabel.frame.origin.y,
                                     width: leftLabel.frame.size.width + 6.0,
                                     height: leftLabel.frame.size.height)
            leftLabel.textAlignment = .center
            //leftLabel.layer.backgroundColor = settings.referenceLabelBackgoundColor.cgColor
            leftLabel.layer.backgroundColor = UIColor.clear.cgColor
        }
        do {
            rightLabel.frame = CGRect(x: rightLabel.frame.origin.x - 3.0,
                                      y: rightLabel.frame.origin.y,
                                      width: rightLabel.frame.size.width + 6.0,
                                      height: rightLabel.frame.size.height)
            rightLabel.layer.backgroundColor = settings.referenceLabelBackgoundColor.cgColor
            rightLabel.textAlignment = .center
        }
    }
    
    private func addLine(from: CGPoint, to: CGPoint, withGaps gaps: [(start: CGFloat, end: CGFloat)], in path: UIBezierPath, pointindex index: Int) {
        
        // If there are no gaps, just add a single line.
        if (gaps.count <= 0) {
            addLine(from: from, to: to, in: path, pointindex: index)
        }
        // If there is only 1 gap, it's just two lines.
        else if (gaps.count == 1) {
            
            let gapLeft = CGPoint(x: gaps.first!.start, y: from.y)
            let gapRight = CGPoint(x: gaps.first!.end, y: from.y)
            
            if settings.shouldDrawReferenceLineGuardLineForRightLabels == true {
                if gapLeft.x - from.x > to.x - gapRight.x {
                    addLine(from: from, to: gapLeft, in: path, pointindex: index)
                    addLeftGapLine(from: gapRight, to: to, in: path, pointindex: index)
                    if from.x > self.leftGuardLongestLabelLineStartX {
                        self.leftGuardLongestLabelLineStartX = from.x
                    }
                }
                else {
                    addLeftGapLine(from: from, to: gapLeft, in: path, pointindex: index)
                    addLine(from: gapRight, to: to, in: path, pointindex: index)
                    if from.x > self.leftGuardLongestLabelLineStartX {
                        self.leftGuardLongestLabelLineStartX = from.x
                    }
                }
            }
            else if settings.shouldDrawReferenceLineGuardLineForLeftLabels == true {
                if gapLeft.x - from.x > to.x - gapRight.x {
                    addLine(from: from, to: gapLeft, in: path, pointindex: index)
                    addLeftGapLine(from: gapRight, to: to, in: path, pointindex: index)
                    if from.x > self.leftGuardLongestLabelLineStartX {
                        self.leftGuardLongestLabelLineStartX = from.x
                    }
                }
                else {
                    addLeftGapLine(from: from, to: gapLeft, in: path, pointindex: index)
                    addLine(from: gapRight, to: to, in: path, pointindex: index)
                    if gapRight.x > self.leftGuardLongestLabelLineStartX {
                        self.leftGuardLongestLabelLineStartX = gapRight.x
                    }
                }
            }
            else {
                addLine(from: from, to: gapLeft, in: path, pointindex: index)
                addLine(from: gapRight, to: to, in: path, pointindex: index)
            }
        }
        // If there are many gaps, we have a series of intermediate lines.
        else {
            
            let firstGap = gaps.first!
            let lastGap = gaps.last!
            
            let firstGapLeft = CGPoint(x: firstGap.start, y: from.y)
            let lastGapRight = CGPoint(x: lastGap.end, y: to.y)
            
            // Add the first line to the start of the first gap
            addLine(from: from, to: firstGapLeft, in: path, pointindex: index)
            
            // Add lines between all intermediate gaps
            for i in 0 ..< gaps.count - 1 {
                
                let startGapEnd = gaps[i].end
                let endGapStart = gaps[i + 1].start
                
                let lineStart = CGPoint(x: startGapEnd, y: from.y)
                let lineEnd = CGPoint(x: endGapStart, y: from.y)
                
                addLine(from: lineStart, to: lineEnd, in: path, pointindex: index)
            }
            
            // Add the final line to the end
            addLine(from: lastGapRight, to: to, in: path, pointindex: index)
        }
    }
    
    private func addLine(from: CGPoint, to: CGPoint, in path: UIBezierPath, pointindex index: Int) {
        if settings.shouldDrawReferenceLineGuardLineForRightLabels == true {
            if settings.shouldDrawOutterReferenceLineAsSolidWhenReferenceLineStyleIsDashed == true && index == 0 {
                if settings.referenceLineStyle == ScrollableGraphViewReferenceLineStyle.solid {
                    path.move(to: from)
                    path.addLine(to: to)
                }
                else if settings.referenceLineStyle == ScrollableGraphViewReferenceLineStyle.dashed && self.referenceBottomGuardLineLayer == nil {
                    let borderLayer = CAShapeLayer()
                    borderLayer.name = "borderLayer"
                    borderLayer.frame = self.frame
                    borderLayer.fillColor = UIColor.clear.cgColor
                    borderLayer.strokeColor = self.referenceLineLayer.strokeColor
                    
                    let pathline = UIBezierPath()
                    pathline.move(to: from)
                    pathline.addLine(to: to)
                    
                    borderLayer.path = pathline.cgPath
                    self.referenceLineLayer.addSublayer(borderLayer)
                    self.referenceBottomGuardLineLayer = borderLayer
                }
            }
            else if settings.shouldDrawOutterReferenceLineAsSolidWhenReferenceLineStyleIsDashed == true && index != 0 {
                if settings.referenceLineStyle == ScrollableGraphViewReferenceLineStyle.solid {
                    path.move(to: from)
                    path.addLine(to: to)
                }
                else if settings.referenceLineStyle == ScrollableGraphViewReferenceLineStyle.dashed {
                    let borderLayer = CAShapeLayer()
                    borderLayer.name = "borderLayer"
                    borderLayer.frame = self.frame
                    borderLayer.fillColor = UIColor.clear.cgColor
                    borderLayer.strokeColor = self.referenceLineLayer.strokeColor
                    borderLayer.lineJoin = kCALineJoinRound
                    
                    let pathline = UIBezierPath()
                    pathline.move(to: to)
                    pathline.addLine(to: CGPoint(x: to.x - 3, y: to.y))
                    
                    borderLayer.path = pathline.cgPath
                    self.referenceLineLayer.addSublayer(borderLayer)
                    
                    path.move(to: from)
                    path.addLine(to: to)
                }
            }
            else {
                path.move(to: from)
                path.addLine(to: to)
            }
        }
        else if settings.shouldDrawReferenceLineGuardLineForLeftLabels == true {
            if settings.shouldDrawOutterReferenceLineAsSolidWhenReferenceLineStyleIsDashed == true && index == 0 {
                if settings.referenceLineStyle == ScrollableGraphViewReferenceLineStyle.solid {
                    path.move(to: from)
                    path.addLine(to: to)
                }
                else if settings.referenceLineStyle == ScrollableGraphViewReferenceLineStyle.dashed {
                    if self.referenceBottomGuardLineLayer != nil {
                        self.referenceBottomGuardLineLayer?.removeFromSuperlayer()
                        self.referenceBottomGuardLineLayer = nil;
                    }
                    // bottom line
                    let borderLayer = CAShapeLayer()
                    borderLayer.name = "borderLayer"
                    borderLayer.frame = self.frame
                    borderLayer.fillColor = UIColor.clear.cgColor
                    borderLayer.strokeColor = self.referenceLineLayer.strokeColor
                    
                    let pathline = UIBezierPath()
                    if self.leftGuardLongestLabelLineStartX == 0 {
                        //pathline.move(to: from)
                        //pathline.addLine(to: to)
                    }
                    else {
                        pathline.move(to: CGPoint(x: self.leftGuardLongestLabelLineStartX, y: from.y))
                        pathline.addLine(to: to)
                        
                        path.move(to: from)
                        path.addLine(to: CGPoint(x: self.leftGuardLongestLabelLineStartX, y: to.y))
                    }
                    
                    borderLayer.path = pathline.cgPath
                    self.referenceLineLayer.addSublayer(borderLayer)
                    self.referenceBottomGuardLineLayer = borderLayer
                }
            }
            else if settings.shouldDrawOutterReferenceLineAsSolidWhenReferenceLineStyleIsDashed == true && index != 0 {
                if settings.referenceLineStyle == ScrollableGraphViewReferenceLineStyle.solid {
                    path.move(to: from)
                    path.addLine(to: to)
                }
                else if settings.referenceLineStyle == ScrollableGraphViewReferenceLineStyle.dashed {
                    
                    self.leftGuardGuides.enumerateObjects({ (object, index, stop) in
                        if let layer: CAShapeLayer = object as? CAShapeLayer {
                            if layer.frame.equalTo(self.frame) == false {
                                layer.removeFromSuperlayer()
                            }
                        }
                    })
                    
                    // 눈금
                    do {
                        let borderLayer = CAShapeLayer()
                        borderLayer.name = "borderLayer"
                        borderLayer.frame = self.frame
                        borderLayer.fillColor = UIColor.clear.cgColor
                        borderLayer.strokeColor = self.referenceLineLayer.strokeColor
                        borderLayer.lineJoin = kCALineJoinRound
                        
                        let pathline = UIBezierPath()
                        if self.leftGuardLongestLabelLineStartX == 0 {
                            pathline.move(to: from)
                            pathline.addLine(to: CGPoint(x: from.x + 3, y: from.y))
                        }
                        else {
                            pathline.move(to: CGPoint(x: self.leftGuardLongestLabelLineStartX, y: from.y))
                            pathline.addLine(to: CGPoint(x: self.leftGuardLongestLabelLineStartX + 3, y: from.y))
                        }
                        
                        borderLayer.path = pathline.cgPath
                        self.referenceLineLayer.addSublayer(borderLayer)
                        self.leftGuardGuides.add(borderLayer)
                    }
                    
                    // dash
                    if self.leftGuardLongestLabelLineStartX == 0 {
                        //path.move(to: from)
                        //path.addLine(to: to)
                    }
                    else {
                        path.move(to: CGPoint(x: self.leftGuardLongestLabelLineStartX + 3.0, y: from.y))
                        path.addLine(to: to)
                    }
                    
                    // vertical guard line
                    if index == 4 {
                        let borderLayer = CAShapeLayer()
                        borderLayer.name = "borderLayer"
                        borderLayer.frame = self.frame
                        borderLayer.fillColor = UIColor.clear.cgColor
                        borderLayer.strokeColor = self.referenceLineLayer.strokeColor
                        borderLayer.lineJoin = kCALineJoinRound
                        
                        let pathline = UIBezierPath()
                        pathline.move(to: CGPoint(x: from.x + 3, y: self.frame.origin.y - 3))
                        pathline.addLine(to: CGPoint(x: from.x + 3, y: self.frame.origin.y + self.frame.size.height - self.bottomMargin + 3.0))
                        
                        borderLayer.path = pathline.cgPath
                        self.referenceLineLayer.addSublayer(borderLayer)
                        self.leftGuardGuides.add(borderLayer)
                    }
                }
            }
            else {
                path.move(to: from)
                path.addLine(to: to)
            }
        }
        else {
            path.move(to: from)
            path.addLine(to: to)
        }
    }
    
    private func addLeftGapLine(from: CGPoint, to: CGPoint, in path: UIBezierPath, pointindex index: Int) {
        if settings.shouldDrawOutterReferenceLineAsSolidWhenReferenceLineStyleIsDashed == true {
            if settings.referenceLineStyle == ScrollableGraphViewReferenceLineStyle.solid {
                path.move(to: from)
                path.addLine(to: to)
            }
            else if settings.referenceLineStyle == ScrollableGraphViewReferenceLineStyle.dashed {
                // do nothing
            }
        }
        else {
            path.move(to: from)
            path.addLine(to: to)
        }
    }
    
    private func boundingSize(forText text: String) -> CGSize {
        return (text as NSString).size(withAttributes: [NSAttributedStringKey.font:self.settings.referenceLineLabelFont])
    }
    
    private func calculateYAxisValue(for point: CGPoint) -> Double {
        
        let graphHeight = self.frame.size.height - (topMargin + bottomMargin)
        
        //                                          value = the corresponding value on the graph for any y co-ordinate in the view
        //           y - t                          y = the y co-ordinate in the view for which we want to know the corresponding value on the graph
        // value = --------- * (min - max) + max    t = the top margin
        //             h                            h = the height of the graph space without margins
        //                                          min = the range's current mininum
        //                                          max = the range's current maximum
        
        var value = (((point.y - topMargin) / (graphHeight)) * CGFloat((self.currentRange.min - self.currentRange.max))) + CGFloat(self.currentRange.max)
        
        // Sometimes results in "negative zero"
        if (value == 0) {
            value = 0
        }
        
        return Double(value)
    }
    
    private func calculateYPositionForYAxisValue(value: Double) -> CGFloat {
        
        // Just an algebraic re-arrangement of calculateYAxisValue
        let graphHeight = self.frame.size.height - (topMargin + bottomMargin)
        var y = ((CGFloat(value - self.currentRange.max) / CGFloat(self.currentRange.min - self.currentRange.max)) * graphHeight) + topMargin
        
        if (y == 0) {
            y = 0
        }
        
        return y
    }
    
    private func createLabel(withText text: String, pointindex index: Int) -> UILabel {
        let label = UILabel()
        
        let customLabelText: String? = self.dataSource?.labelCustomText(forGraph:self.settings, atIndex:index)
        if customLabelText != nil {
            label.text = customLabelText
        }
        else {
            label.text = text
        }
        if customLabelText == "" {
            label.alpha = 0.0
        }
        label.textColor = self.settings.referenceLineLabelColor
        label.font = self.settings.referenceLineLabelFont
        
        let transfrom :CATransform3D? = self.settings.referenceLineLabelTransForm
        if transfrom != nil {
            let affine: CGAffineTransform = CGAffineTransform(a: transfrom!.m11, b: transfrom!.m12, c: transfrom!.m21, d: transfrom!.m22, tx: transfrom!.m41, ty: transfrom!.m42)
            label.transform = affine
        }
        
        return label
    }
    
    // Public functions to update the reference lines with any changes to the range and viewport (phone rotation, etc).
    // When the range changes, need to update the max for the new range, then update all the labels that are showing for the axis and redraw the reference lines.
    func set(range: (min: Double, max: Double)) {
        self.currentRange = range
        self.referenceLineLayer.path = createReferenceLinesPath().cgPath
    }
    
    func set(viewportWidth: CGFloat, viewportHeight: CGFloat) {
        self.frame.size.width = viewportWidth
        self.frame.size.height = viewportHeight
        self.referenceLineLayer.path = createReferenceLinesPath().cgPath
    }
}
