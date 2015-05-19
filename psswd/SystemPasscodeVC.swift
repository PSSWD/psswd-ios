//
//  SystemPasscodeVC.swift
//  psswd
//
//  Created by Daniil on 03.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

import UIKit

class SystemPasscodeVC: UIViewController
{
	private var code = ""

	@IBOutlet weak private var topTitleLabel: UILabel!
	var topTitle = "Введите пароль"
	
	@IBOutlet weak private var dotsView: UIView!

	@IBOutlet weak private var keypadView: UIView!
	
	@IBOutlet weak private var buttonLeft: UIButton!
	var buttonLeftTitle = ""
	var buttonLeftAction: (() -> Void)? = nil

	@IBOutlet weak private var buttonRight: UIButton!
	var buttonRightTitle = "Назад"
	var buttonRightAction: (() -> Void)? = nil
	private var buttonRightActionCache: (() -> Void)? = nil

	var onSubmit: (code: String) -> Void = { (code: String) -> Void in }

	@IBAction func leftButtonPressed(sender: UIButton) {
		if nil != buttonLeftAction { buttonLeftAction!() }
	}
	@IBAction func rightButtonPressed(sender: UIButton) {
		if nil != buttonRightAction { buttonRightAction!() }
	}
	
	@IBAction func keypadButtonTouchDown(sender: UIButton) {
		sender.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1)
	}
	@IBAction func keypadButtonTouchUpOutside(sender: UIButton) {
		sender.backgroundColor = UIColor.clearColor()
	}
	@IBAction func keypadButtonPressed(sender: UIButton) {
		sender.backgroundColor = UIColor.clearColor()
		
		if countElements(code) >= 6 { return }
		code = code + sender.titleForState(UIControlState.Normal)!
		
		updateDots()
	}
	private func updateDots()
	{
		for (i, el) in enumerate(self.dotsView.subviews as [UIView!])
		{
			if countElements(code) <= i
			{
				el.backgroundColor = UIColor.clearColor()
			}
			else
			{
				el.backgroundColor = UIColor.whiteColor()
			}
		}
		
		if countElements(code) == 0
		{
			if "" == buttonRightTitle
			{
				buttonRight.hidden = true
			}
			else
			{
				buttonRight.hidden = false
				buttonRight.setTitle(buttonRightTitle, forState: UIControlState.Normal)
				buttonRightAction = buttonRightActionCache
			}
		}
		else
		{
			buttonRight.hidden = false
			buttonRight.setTitle("Удалить", forState: UIControlState.Normal)
			var rightPx = buttonRight.frame.origin.x + buttonRight.frame.size.width
			buttonRightAction = {
				self.code = self.code.substringToIndex( advance(self.code.startIndex, countElements(self.code) - 1) )
				self.updateDots()
			}
		}
		
		if countElements(code) >= 6
		{
			onSubmit(code: code)
		}
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		self.navigationController?.setNavigationBarHidden(true, animated: false)
		
		topTitleLabel.text = topTitle
		
		// --- WTF?! ---
		var time = dispatch_time(DISPATCH_TIME_NOW, 10_000_000)
		dispatch_after(time, dispatch_get_main_queue(), {
			// SOOQUA! keypadView.subviews.count greater then zero only here, solve this problem!
			for el in self.keypadView.subviews
			{
				if let button = el as? UIButton
				{
					//println("button with text \(button.titleLabel?.text) and size \(button.frame.size.width)x\(button.frame.size.height)")
					button.layer.cornerRadius = button.frame.size.width / 2
					button.layer.borderWidth = 1
					button.layer.borderColor = UIColor.whiteColor().CGColor
					//button.layer.masksToBounds = true
					button.clipsToBounds = true
				}
			}
			for el in self.dotsView.subviews as [ UIView! ]
			{
				el.backgroundColor = UIColor.clearColor()
				el.layer.cornerRadius = el.frame.size.width / 2
				el.layer.borderWidth = 1
				el.layer.borderColor = UIColor.whiteColor().CGColor
				//el.clipsToBounds = true
			}
		})
		// --- / WTF?! ---
		
		if "" == buttonLeftTitle
		{
			buttonLeft.hidden = true
		}
		else
		{
			buttonLeft.setTitle(buttonLeftTitle, forState: .Normal)
		}
		
		if "" == buttonRightTitle
		{
			buttonRight.hidden = true
		}
		else
		{
			buttonRight.setTitle(buttonRightTitle, forState: .Normal)
			buttonRightAction = { () -> Void in
				if 0 < self.navigationController?.viewControllers.count
				{
					self.navigationController?.popViewControllerAnimated(true)
				}
				return
			}
		}
		buttonRightActionCache = buttonRightAction
	}
	
	func clear(){
		code = ""
		updateDots()
	}
	
	func shakeDots(){
		var animation: CABasicAnimation = CABasicAnimation(keyPath: "position")
		animation.duration = 0.05
		animation.repeatCount = 4
		animation.autoreverses = true
		animation.fromValue = NSValue(CGPoint: CGPointMake(self.dotsView.center.x - 20, self.dotsView.center.y))
		animation.toValue = NSValue(CGPoint: CGPointMake(self.dotsView.center.x + 20, self.dotsView.center.y))
		self.dotsView.layer.addAnimation(animation, forKey: "position")
	}
}
