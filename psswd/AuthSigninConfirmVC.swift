//
//  AuthSigninConfirmVC.swift
//  psswd
//
//  Created by Daniil on 09.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

import UIKit

class AuthSigninConfirmVC: UITableViewController
{
	@IBOutlet weak var confirmCode_field: UITextField!
	
	var masterpass = ""

	override func viewDidLoad()
	{
		super.viewDidLoad()
	}
	
	@IBAction func nextPressed(sender: AnyObject) {
		var confirm_code = confirmCode_field.text!
		
		var masterpass_getCodes_public = Crypto.Bytes(fromString: masterpass).append(API.constants.salt_masterpass_getcodes_public).getSHA1()
		println("masterpass_getCodes_public \(masterpass_getCodes_public)")
		
		var params = [
			"device_id": Storage.getString("device_id")!,
			"masterpass_getcodes_public": masterpass_getCodes_public,
			"confirm_code": confirm_code
		] as [String: AnyObject]
		
		API.call("device.confirm", params: params, callback: { rdata in
			let code = rdata["code"] as! Int
			
			switch code {
				case 0:
					Storage.remove("email")

					var masterpass_getCodes_private = Crypto.Bytes(fromString: self.masterpass).append(API.constants.salt_masterpass_getcodes_private).getSHA1()
					println("masterpass_getCodes_private \(masterpass_getCodes_private)")

					var clientCodes = Schemas.utils.schemaBytesToData( Crypto.Cryptoblender.decrypt(rdata["data"] as! Crypto.Bytes, withKey: masterpass_getCodes_private) ) as! [Crypto.Bytes]
					
					Storage.setBytes(clientCodes[1], forKey: "code_client")
					Storage.setBytes(clientCodes[2], forKey: "code_client_pass")
					Storage.setBytes(clientCodes[3], forKey: "code_client_getdata")
				
					var pass = clientCodes[0]
						.concat( Storage.getBytes("code_client")! )
						.concat( Storage.getBytes("code_client_pass")! )
						.concat( API.constants.salt_pass )
						.getSHA1()
					
					var params2 = [
						"device_id": Storage.getString("device_id")!,
						"pass": pass
					] as [String: AnyObject]
				
					API.call("device.auth", params: params2, callback: { rdata2 in
						let code2 = rdata2["code"] as! Int
						switch code2 {
							case 0:
								API.code_user = clientCodes[0].toSymbols()
								var vc = self.storyboard?.instantiateViewControllerWithIdentifier("MainPassListVC") as! UITableViewController
								self.navigationController!.setViewControllers([ vc ], animated: false)
							default:
								API.unknownCode(rdata2)
						}
					})
				case 601:
					var attempts = rdata["data"] as! Int
					Funcs.message("Неверный код активации. Осталось попыток: \(attempts)")
					self.confirmCode_field.text = ""
				case 602:
					Funcs.message("Ошибка подтверждения. Пройдите процедуру входа заново.")
					Storage.clear()
					self.confirmCode_field.text = ""
				default:
					API.unknownCode(rdata)
			}
		})
	}
}
