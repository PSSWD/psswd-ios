//
//  ViewController.swift
//  psswd
//
//  Created by Daniil on 20.12.14.
//  Copyright (c) 2014 kirick. All rights reserved.
//

import UIKit

class InitViewController: UIViewController {

	override func viewDidLoad()
	{
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		//Storage.clear(); Storage.set("daniil@kirick.me", forKey: "email"); return;
		
		//Funcs.imageFolder.clean()
		//Funcs.imageFolder.removeAll()
		
		Schemas.create()
		Services.create()
		
		Funcs.ActivityObserver.sharedInstance()
		
		//println(UIDevice.currentDevice().model)
		
		var vc: UIViewController

		if nil != Storage.get("device_id") && nil != Storage.getString("code_client")
		{
			vc = Funcs.getStartupPasscodeScreen()
		}
		else
		{
			vc = self.storyboard?.instantiateViewControllerWithIdentifier("AuthEmailVC") as! UITableViewController
		}
		
		self.navigationController!.setViewControllers([ vc ], animated: false)
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

