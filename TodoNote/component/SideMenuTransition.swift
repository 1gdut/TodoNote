import UIKit

class SideMenuTransitionManager: NSObject, UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SideMenuAnimator(isPresenting: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SideMenuAnimator(isPresenting: false)
    }
}

class SideMenuAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let isPresenting: Bool
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // 获取转场上下文中的 key
        // isPresenting: fromView 是 MainVC(底部不动), toView 是 AIViewController(侧边栏出来的)
        // dismiss: fromView 是 AIViewControlelr(要走的), toView 是 MainVC(底部的)
        
        let key: UITransitionContextViewControllerKey = isPresenting ? .to : .from
        guard let controller = transitionContext.viewController(forKey: key) else { return }
        
        // 容器视图
        let containerView = transitionContext.containerView
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // 设定初始和结束位置
        // 模拟 Push：新视图从右边进，现在我们要从左边进
        // Push from Left:
        // Present: View 应该从 (-width, 0) 移动到 (0, 0)
        // Dismiss: View 应该从 (0, 0) 移动到 (-width, 0)
        
        let finalFrame = isPresenting ? CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight) : CGRect(x: -screenWidth, y: 0, width: screenWidth, height: screenHeight)
        let initialFrame = isPresenting ? CGRect(x: -screenWidth, y: 0, width: screenWidth, height: screenHeight) : CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        
        if isPresenting {
            containerView.addSubview(controller.view)
            controller.view.frame = initialFrame
        }
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       options: .curveEaseInOut) {
            controller.view.frame = finalFrame
        } completion: { finished in
            if !self.isPresenting {
                controller.view.removeFromSuperview()
            }
            transitionContext.completeTransition(finished)
        }
    }
}
