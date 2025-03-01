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
        circleLayer.add(rotation, forKey: "rotationAnimation")
        
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.fromValue = 0.35
        strokeAnimation.toValue = 1
        strokeAnimation.duration = 2
        strokeAnimation.repeatCount = .infinity
        circleLayer.add(strokeAnimation, forKey: "strokeEndAnimation")
    }
    
    func stopAnimating() {
        isHidden = true
        circleLayer.removeAllAnimations()
    }
    
}

// MARK: - Private

private extension CustomActivityIndicator {
    
    func setup() {
        let rect = CGRect(x: 0, y: 0, width: 30, height: 30)
        let circularPath = UIBezierPath(ovalIn: rect)
        
        circleLayer.path = circularPath.cgPath
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.strokeColor = UIColor.systemGray.cgColor
        circleLayer.lineWidth = 2
        circleLayer.strokeEnd = 0.35
        circleLayer.lineCap = .round
        circleLayer.frame = rect
        
        layer.addSublayer(circleLayer)
        
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 40),
            heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
}
