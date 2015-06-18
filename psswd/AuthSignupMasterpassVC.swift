//
//  AuthSignupMasterpassVC.swift
//  psswd
//
//  Created by Daniil on 02.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

import UIKit

class AuthSignupMasterpassVC: UITableViewController
{
	@IBOutlet weak var masterpassField: UITextField!
	@IBOutlet weak var masterpassRetypeField: UITextField!
	override func viewDidLoad()
	{
		super.viewDidLoad()
	}
	@IBAction func nextPressed(sender: AnyObject) {
		println("next pressed")
		
		let masterpass = masterpassField.text
		
		if count(masterpass) < 10 {
			UIAlertView(title: "Ошибка", message: "Мастерпароль слишком короткий. Минимальная длина мастерпароля — 10 символов.", delegate: self, cancelButtonTitle: "OK").show()
			return
		}
		
		if count(masterpass) > 64 {
			UIAlertView(title: "Ошибка", message: "Мастерпароль слишком длинный. Максимальная длина мастерпароля — 64 символа.", delegate: self, cancelButtonTitle: "OK").show()
			return
		}
		
		if masterpass != masterpassRetypeField.text {
			UIAlertView(title: "Ошибка", message: "Введённые мастерпароли не совпадают.", delegate: self, cancelButtonTitle: "OK").show()
			return
		}
		
		var passcodeVC = self.storyboard?.instantiateViewControllerWithIdentifier("SystemPasscodeVC") as! SystemPasscodeVC
		passcodeVC.topTitle = "Придумайте пароль"
		passcodeVC.onSubmit = { (code_user: String) -> Void in
			var passcodeRetypeVC = self.storyboard?.instantiateViewControllerWithIdentifier("SystemPasscodeVC") as! SystemPasscodeVC
			passcodeRetypeVC.topTitle = "Повторите пароль"
			passcodeRetypeVC.onSubmit = { (codeRetype: String) -> Void in
				if code_user != codeRetype {
					UIAlertView(title: "Ошибка", message: "Пароли не совпадают", delegate: passcodeRetypeVC, cancelButtonTitle: "OK").show()
					self.navigationController!.popViewControllerAnimated(true)
					return
				}
				
				var email = Storage.getString("email")
				
				assert(nil != email, "Can't get email.")

				var code_client = Crypto.Bytes(randomWithLength: 20)
				,	code_client_pass = Crypto.Bytes(randomWithLength: 32)
				,	code_client_getdata = Crypto.Bytes(randomWithLength: 32)
				
				var masterpass_getCodes_public = Crypto.Bytes(fromString: masterpass).append(API.constants.salt_masterpass_getcodes_public).getSHA1()
				,	masterpass_getCodes_private = Crypto.Bytes(fromString: masterpass).append(API.constants.salt_masterpass_getcodes_private).getSHA1()
				
				var clientCodes_toenc = Schemas.utils.dataToSchemaBytes(0x3003, input_data: [Crypto.Bytes(fromString: code_user), code_client, code_client_pass, code_client_getdata])
				
				var clientCodes_enc = Crypto.Cryptoblender.encrypt(clientCodes_toenc, withKey: masterpass_getCodes_private)
				var clientCodes_enc_enc = Crypto.Cryptoblender.encrypt(clientCodes_enc, withKey: masterpass_getCodes_public)
				var clientCodes_enc_enc_hash = clientCodes_enc_enc.getSHA1()
				
				//var pass = Crypto.SHA1(code_user + code_client + code_client_pass + constants.salt_pass)
				
				var pass = Crypto.Bytes(fromString: code_user)
					.append(code_client)
					.append(code_client_pass)
					.append(API.constants.salt_pass)
					.getSHA1()
				
				var requestData = [
					"email": email!,
					"pass": pass,
					"clientCodes_enc_enc": clientCodes_enc_enc,
					"clientCodes_enc_enc_hash": clientCodes_enc_enc_hash,
					"app_id": API.app.app_id,
					"app_secret": API.app.app_secret
				] as [String: AnyObject]
				
				API.call("reg.start", params: requestData, callback: { rdata in
				
					let code = rdata["code"] as! Int

					switch code {
						case 0:
							Storage.setBytes(code_client, forKey: "code_client")
							Storage.setBytes(code_client_pass, forKey: "code_client_pass")
							Storage.setBytes(code_client_getdata, forKey: "code_client_getdata")
						
							API.code_user = code_user
						
							var vc = self.storyboard?.instantiateViewControllerWithIdentifier("AuthSignupConfirmVC") as! UITableViewController
							self.navigationController!.pushViewController(vc, animated: true)
						default:
							API.unknownCode(rdata)
					}
				})
			}
			self.navigationController!.pushViewController(passcodeRetypeVC, animated: true)
		}
		self.navigationController!.pushViewController(passcodeVC, animated: true)
	}
	
	private func randomString(length: Int) -> String {
		var syms = Array("0123456789" + "abcdefghijklmnopqrstuvwxyz" + "ABCDEFGHIJKLMNOPQRSTUVWXYZ" + "!@#$%&§.")
		var res = ""
		while count(res) < length {
			res = "\(res)\(syms[ Int( MTRandom().randomUInt32From(0, to: UInt32(syms.count - 1)) ) ])"
		}
		return res
	}
}
