//
//  Copyright © 2014 Yalantis
//  Licensed under the MIT license: http://opensource.org/licenses/MIT
//

import QuartzCore

class AnimationDelegate: NSObject, CAAnimationDelegate {
    private let completion: () -> Void

    init(completion: () -> Void) {
        self.completion = completion
    }
    
    func animationDidStart(anim: CAAnimation) {
        
    }

    dynamic func animationDidStop(_: CAAnimation, finished: Bool) {
        completion()
    }
}
