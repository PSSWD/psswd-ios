//
//  AuthSigninMasterpassVC.swift
//  psswd
//
//  Created by Daniil on 09.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

import UIKit

class AuthSigninMasterpassVC: UITableViewController
{
	@IBOutlet weak var masterpassField: UITextField!

	override func viewDidLoad()
	{
		super.viewDidLoad()
	}
	
	@IBAction func nextPressed(sender: AnyObject) {
		var masterpass = masterpassField.text!
		
		var masterpass_getCodes_public = Crypto.Bytes(fromString: masterpass).append(API.constants.salt_masterpass_getcodes_public).getSHA1()
		
		var params = [
			"email": Storage.getString("email")!,
			"masterpass_getcodes_public": masterpass_getCodes_public,
			"app_id": API.app.app_id,
			"app_secret": API.app.app_secret
		] as [String: AnyObject]
		
		API.call("device.create", params: params, callback: { rdata in
			let code = rdata["code"] as! Int
			
			switch code {
				case 0:
					Storage.set(rdata["data"] as! String, forKey: "device_id")
				
					var vc = self.storyboard?.instantiateViewControllerWithIdentifier("AuthSigninConfirmVC") as! AuthSigninConfirmVC
					vc.masterpass = masterpass
					self.navigationController!.pushViewController(vc, animated: true)
				case 201:
					Funcs.message("Неверный мастерпароль.")
					self.masterpassField.text = ""
				default:
					API.unknownCode(rdata)
			}
		})
	}
}
