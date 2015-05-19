//
//  UINavigationController.swift
//  psswd
//
//  Created by Daniil on 05.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

import UIKit

class MyNavigationController: UINavigationController, UINavigationControllerDelegate
{
	override func viewWillAppear(animated: Bool)
	{
		super.viewWillAppear(animated)
		self.delegate = self
	}
	
	func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool)
	{
		// hide navigation bar
		if nil == viewController as? SystemPasscodeVC
		{
			self.setNavigationBarHidden(false, animated: false)
		}
		
		// reset navigationbar's design
		var bar = navigationController.navigationBar
		bar.barStyle = UIBarStyle.Default
		bar.tintColor = nil
		bar.barTintColor = nil
		bar.translucent = true
		bar.setBackgroundImage(nil, forBarPosition: UIBarPosition.Any, barMetrics: UIBarMetrics.Default)
		bar.shadowImage = nil
		
		// light status bar
		if nil != viewController as? SystemPasscodeVC {
			UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
		}
		else
		{
			UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
		}
	}
	
	override func nextResponder() -> UIResponder? {
		Funcs.ActivityObserver.sharedInstance().gesture()
		return super.nextResponder()
	}

	override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent) {
		if ( event.subtype == UIEventSubtype.MotionShake )
		{
			Funcs.lockApp()
		}
	}
}
