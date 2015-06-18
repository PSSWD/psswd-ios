//
//  AuthEmailVC.swift
//  psswd
//
//  Created by Daniil on 29.12.14.
//  Copyright (c) 2014 kirick. All rights reserved.
//

import UIKit

class AuthEmailVC: UITableViewController
{
	@IBOutlet weak var emailField: UITextField!

	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		if nil != Storage.getString("email")
		{
			emailField.text = Storage.getString("email")!
		}
	}

	@IBAction func nextPressed(sender: AnyObject)
	{
		var email = self.emailField.text
		println(email)
		API.call("reg.status", params: email, callback: { rdata in
			var success = { () -> Void in
				Storage.set(email, forKey: "email")
				self.emailField.text = ""
			}
			var code = rdata["code"] as! Int
			switch code {
				case 0:
					var user_status = rdata["data"] as! Int
					switch user_status {
						case 0:
							var vc = self.storyboard?.instantiateViewControllerWithIdentifier("AuthSigninMasterpassVC") as! UIViewController
							self.navigationController!.pushViewController(vc, animated: true)
							success()
						case 1:
							var vc = self.storyboard?.instantiateViewControllerWithIdentifier("AuthSignupConfirmVC") as! UIViewController
							self.navigationController!.pushViewController(vc, animated: true)
							success()
						default:
							UIAlertView(title: "Ошибка", message: "Неизвестный статус пользователя.", delegate: self, cancelButtonTitle: "OK").show()
					}
				case 301:
					var vc = self.storyboard?.instantiateViewControllerWithIdentifier("AuthSignupMasterpassVC") as! UITableViewController
					self.navigationController!.pushViewController(vc, animated: true)
					success()
				default:
					API.unknownCode(rdata)
			}
		})
	}
}