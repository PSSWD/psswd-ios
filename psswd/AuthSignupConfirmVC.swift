//
//  AuthSignupConfirmVC.swift
//  psswd
//
//  Created by Daniil on 06.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

import UIKit

class AuthSignupConfirmVC: UITableViewController
{
	@IBOutlet weak var codeConfirm_field: UITextField!

	override func viewDidLoad()
	{
		super.viewDidLoad()
	}

	@IBAction func nextPressed(sender: AnyObject) {
		var confirm_code = codeConfirm_field.text!
		,	email = Storage.getString("email")
		
		if nil == email {
			UIAlertView(title: "Ошибка", message: "Внутренняя критическая ошибка.", delegate: self, cancelButtonTitle: "OK").show()
			return
		}
		
		var request_data = [
			"email": email!,
			"confirm_code": confirm_code
		]
		
		API.call("reg.confirm", params: request_data, callback: { rdata in
			let code = rdata["code"] as Int
			
			switch code {
				case 0:
					if let data = rdata["data"] as? [String: AnyObject]
					{
						let device_id = data["device_id"] as String
						Storage.set(device_id, forKey: "device_id")
					
						Storage.remove("email")
					
						if nil == API.code_user
						{
							var vc = Funcs.getStartupPasscodeScreen()
							self.navigationController!.setViewControllers([ vc ], animated: false)
						}
						else
						{
							var vc = self.storyboard?.instantiateViewControllerWithIdentifier("MainPassListVC") as UITableViewController
							self.navigationController!.setViewControllers([ vc ], animated: false)
						}
					}
				case 103:
					Funcs.message("Неверный код активации.")
					self.codeConfirm_field.text = ""
				default:
					API.unknownCode(rdata)
			}
		})
	}
}
