import Foundation
import UIKit

class NoteCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var updateTimeLabel: UILabel!
    
    var stringID: String?

    func updateView() {
        titleLabel.fadeTransition(0.2)
        updateTimeLabel.fadeTransition(0.2)
    }
}

extension UIView {
    func fadeTransition(_ duration:CFTimeInterval) {
        self.alpha = 0.0
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.fade
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
        self.isHidden = false
        self.alpha = 1.0
    }

    func fadeOutTransition(_ duration: CFTimeInterval) {
        self.alpha = 0.0
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        animation.type = CATransitionType.fade
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
        self.isHidden = true
        self.alpha = 1.0
    }
}
