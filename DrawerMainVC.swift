//
//  DrawerMainVC.swift
//  BottomDrawer
//
//  Created by Abhay Shankar on 31/10/18.
//  Copyright © 2018 Self. All rights reserved.
//


import UIKit

class DrawerMainVC: UIViewController {

    //MARK: - Private Enums
    
    enum DrawerState {
        case DrawerStateExpanded
        case DrawerStateCollapsed
        
        var opposite: DrawerState {
            switch self {
            case .DrawerStateExpanded:
                return .DrawerStateCollapsed
            case .DrawerStateCollapsed:
                return .DrawerStateExpanded
            }
        }
    }
    

     //MARK: - Private Variables
    
    private let _screenSize     = UIScreen.main.bounds.size
    private let _screenFrame    = UIScreen.main.bounds
    
    
    private var contentVC:UIViewController!
    private var drawerVC:UIViewController!
//    private var vwIndicator:UIView = UIView.init()
    private var topConstraintOfDrawer : NSLayoutConstraint!
   
    private var panGesture : UIPanGestureRecognizer!
    
    private var state : DrawerState = .DrawerStateCollapsed
    private var animator : UIViewPropertyAnimator?
    private let customLayer = CAShapeLayer()
    private let blurEffectView = UIVisualEffectView.init()
    private var isRunning : Bool = false
    
    //MARK: - Public Variables
    /// Set it to scrollview of drawer controller
    var otherScrollview : UIScrollView?  {
        didSet{
            otherScrollview?.isUserInteractionEnabled = false
            otherScrollview?.addObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset), options: [.new,.initial], context: nil)
        }
    }

    /// Padding of Drawer from top in expanded state.
    var paddingFromTop : CGFloat = 100
    /// Visible height of drawer in collapsed state.
    var minimumVisibleHeightOfDrawer : CGFloat = 150
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
   
    deinit {
        otherScrollview?.removeObserver(self, forKeyPath: #keyPath(UIScrollView.contentOffset))
      drawerVC.view.removeGestureRecognizer(panGesture)
    }
     //MARK: - Init
    /// Initialises a controller with contentVC as the main controller and drawerVC as the drawer
    /// - Note: If the drawer controller has a scroll view then pass it to otherScrollview to optimise drawer interaction
    ///         Default values, change according to requirement
    ///         paddingFromTop = 100
    ///         minimumVisibleHeightOfDrawer = 150
    /// - Parameters:
    ///   - contentVC: the main controller
    ///   - drawerVC: the drawer controller

    convenience init(_ contentVC:UIViewController,_ drawerVC:UIViewController) {
        self.init()
        self.contentVC = contentVC
        self.drawerVC = drawerVC
        setupContentVC()
        setupBlurView()
        setupDrawerVC()
        setupPan()
        
        self.view.layoutIfNeeded()
    }
    
     //MARK: - Setup
    
    private func setupBlurView(){
        blurEffectView.isUserInteractionEnabled = false
        contentVC.view.addSubview(blurEffectView)
        contentVC.view.topAnchor.constraint(equalTo: blurEffectView.topAnchor).isActive = true
        contentVC.view.bottomAnchor.constraint(equalTo: blurEffectView.bottomAnchor).isActive = true
        contentVC.view.leftAnchor.constraint(equalTo: blurEffectView.leftAnchor).isActive = true
        contentVC.view.rightAnchor.constraint(equalTo: blurEffectView.rightAnchor).isActive = true
        blurEffectView.frame = contentVC.view.frame
        contentVC.view.layoutIfNeeded()
        blurEffectView.layoutIfNeeded()
    }
    private func setupContentVC(){
        addChild(contentVC)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentVC.view)
        didMove(toParent: contentVC)
        view.topAnchor.constraint(equalTo: contentVC.view.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: contentVC.view.bottomAnchor).isActive = true
        view.leftAnchor.constraint(equalTo: contentVC.view.leftAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: contentVC.view.rightAnchor).isActive = true
    }
    
    private func setupDrawerVC(){
        addChild(drawerVC)
        view.addSubview(drawerVC.view)
        didMove(toParent: drawerVC)
        drawerVC.view.translatesAutoresizingMaskIntoConstraints = false
        topConstraintOfDrawer = drawerVC.view.topAnchor.constraint(equalTo: view.topAnchor, constant: _screenFrame.height - minimumVisibleHeightOfDrawer)
        topConstraintOfDrawer.isActive = true
        view.leftAnchor.constraint(equalTo: drawerVC.view.leftAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: drawerVC.view.rightAnchor).isActive = true
        let heightConstraint = NSLayoutConstraint(item: drawerVC.view, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: _screenFrame.height - paddingFromTop)
        heightConstraint.isActive = true
        setupShadow( drawerVC.view)
        setupCornerRadius(drawerVC.view, radius: 0)
        
        self.otherScrollview?.isUserInteractionEnabled = false
        view.bringSubviewToFront(drawerVC.view)
    }
    
    
    private func setupShadow(_ view:UIView){
        view.layer.shadowColor = UIColor.lightGray.cgColor
        view.layer.shadowOpacity = 0.4
        view.layer.shadowOffset = CGSize.init(width: 0, height: -5)
        view.layer.shadowRadius = 5.0
    }
    
    private func setupCornerRadius(_ viewRadius:UIView,radius:CGFloat){
        
        customLayer.fillColor = UIColor.clear.cgColor
        customLayer.path = UIBezierPath(roundedRect: viewRadius.bounds, cornerRadius: radius).cgPath

        viewRadius.layer.insertSublayer(customLayer, at: 0)
        viewRadius.layer.cornerRadius = radius
    }
    
   
    private func setupPan(){
        panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(panAction(gesture:)))
        panGesture.cancelsTouchesInView = true
        
        panGesture.delegate = self
        drawerVC.view.addGestureRecognizer(panGesture)
    }
    
//MARK: - KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(UIScrollView.contentOffset),
            let otherScrollview = otherScrollview{
            if state == .DrawerStateExpanded && !isRunning && otherScrollview.contentOffset.y < 0.0{// to prevent scroll of drawer's scrollview to go beyond 0
                otherScrollview.isScrollEnabled = false
                otherScrollview.isScrollEnabled = true

            }
        }
    }
    //MARK: - Animated Parameters
    
    fileprivate func updateDrawerTopLayoutConstraints() {
        switch state {
        case .DrawerStateExpanded:
            topConstraintOfDrawer.constant  =  paddingFromTop
            
        case .DrawerStateCollapsed:
            topConstraintOfDrawer.constant  = _screenFrame.height - minimumVisibleHeightOfDrawer
        }
    }
    
    private func getPath()->CGPath{
        return UIBezierPath(roundedRect: view.bounds, cornerRadius: getRadius()).cgPath
    }
    
    private func getRadius()->CGFloat{
        switch state {
        case .DrawerStateExpanded:
            return 20
            
        case .DrawerStateCollapsed:
            return 0
        }
    }
    
    private func getBlurEffect()->UIVisualEffect?{
        switch state {
        case .DrawerStateExpanded:
            return UIBlurEffect.init(style: .regular)
            
        case .DrawerStateCollapsed:
            return nil
        }
    }
    
    //MARK: - Pan Gesture
    @objc private func panAction(gesture:UIPanGestureRecognizer){
        switch gesture.state {
        case .began:
            
            gestureBegan()
        case .possible: break
            
        case .changed:
            gestureChanged(gesture: gesture)
        case .ended:
            gestureEnded(gesture: gesture)
        case .cancelled:break
            
        case .failed:break
            
        }
    }
    private func gestureBegan(){
       
        self.state = self.state.opposite
        isRunning = true
        updateDrawerTopLayoutConstraints()
        contentVC.view.bringSubviewToFront(blurEffectView)
        animator = UIViewPropertyAnimator.init(duration: 0.7, dampingRatio: 0.9) {
            self.view.layoutIfNeeded()
            self.customLayer.path = self.getPath()
            self.drawerVC.view.layer.cornerRadius = self.getRadius()
            self.blurEffectView.effect = self.getBlurEffect()
        }
        animator?.pauseAnimation()
        
        animator?.addCompletion({ (position) in
            if position == .start{
                self.state = self.state.opposite
            }
           self.otherScrollview?.bounces = false
            self.otherScrollview?.isUserInteractionEnabled = self.state == .DrawerStateExpanded
            self.isRunning = false
            self.updateDrawerTopLayoutConstraints()
            self.customLayer.path = self.getPath()
            self.blurEffectView.effect = self.getBlurEffect()
        })
    }
    private func gestureChanged(gesture:UIPanGestureRecognizer){
        if let offsetY = otherScrollview?.contentOffset.y, offsetY > CGFloat(0){
            gesture.setTranslation(gesture.translation(in: drawerVC.view), in: drawerVC.view)
            return
        }
        let transY =  gesture.translation(in: drawerVC.view).y
        let totalDistance = _screenFrame.height - minimumVisibleHeightOfDrawer - paddingFromTop
        
        var distanceTravelled =  transY/totalDistance
        if state == .DrawerStateExpanded{
            distanceTravelled = distanceTravelled * -1
        }
        let progress = min(0.999, max(0.001, distanceTravelled))
      
        animator?.fractionComplete = CGFloat(progress)
    }
    private func gestureEnded(gesture:UIPanGestureRecognizer){
        guard let animator = animator else{return}
        
        let vilocityY = gesture.velocity(in: drawerVC.view).y
        let absVelocity = fabsf(Float(vilocityY))
        if let offsetY = otherScrollview?.contentOffset.y, offsetY > CGFloat(0), state == .DrawerStateCollapsed{
            animator.isReversed = true
        }
        else if absVelocity > 1000.0{
            switch state{
            case .DrawerStateExpanded:
                if vilocityY > 0.0{
                    animator.isReversed = true
                }
            case .DrawerStateCollapsed:
                if vilocityY < 0.0{
                    animator.isReversed = true
                }
            }
        }
        else if animator.fractionComplete < CGFloat(0.50){
            animator.isReversed = true
        }
        animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
    }
}

extension DrawerMainVC:UIGestureRecognizerDelegate{
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gesture = gestureRecognizer as? UIPanGestureRecognizer, gesture === panGesture, let otherGestureRecognizer = otherScrollview else{return false}
        
        if state == .DrawerStateExpanded{
            let velocityY = gesture.velocity(in: drawerVC.view).y
            if velocityY > 0{
                return true
            }
            if otherGestureRecognizer.contentOffset.y > CGFloat(0.00){
                return true 
            }
        }
        return false
    }
}
