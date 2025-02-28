//
//  CustomActivityIndicator.swift
//  Test
//
//  Created by Danil Otmakhov on 28.02.2025.
//

import UIKit

final class CustomActivityIndicator: UIView {
    
    private let circleLayer = CAShapeLayer()
 
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: - Internal

extension CustomActivityIndicator {
    
    func startAnimating() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 1
        rotation.repeatCount = .infinity
        layer.add(rotation, forKey: "rotationAnimation")
    }
    
    func stopAnimating() {
        isHidden = true
        layer.removeAllAnimations()
    }
    
}

// MARK: - Private

private extension CustomActivityIndicator {
    
    func setup() {
        frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        
        let rect = self.bounds
        let circularPath = UIBezierPath(ovalIn: rect)
        
        circleLayer.path = circularPath.cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor.systemGray.cgColor
        circleLayer.lineWidth = 2
        circleLayer.strokeEnd = 0.25
        circleLayer.lineCap = .round
        
        self.layer.addSublayer(circleLayer)
    }
    
}
