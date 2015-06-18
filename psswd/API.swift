//
//  API.swift
//  psswd
//
//  Created by daniil on 10.08.14.
//  Copyright (c) 2014 daniil. All rights reserved.
//

import Foundation
import UIKit

//let publicKeyPath: String = NSBundle.mainBundle().pathForResource("public_key", ofType: "der")!

let API_path = "http://api.psswd.co/method/"

var session_key: Crypto.Bytes = Crypto.Bytes()

var _code_user: String? = nil

class API
{
	struct app
	{
		static var app_id = 2
		static var app_secret = "UMUGk33wV2dL|H~SLS<ZYMZAa5yh5Uao"
		static var app_about = ""
	}
	
	struct constants
	{
		static var salt_masterpass_getcodes_public = Crypto.Bytes(given: [103, 203, 217, 136, 103, 27, 255, 101, 201, 17, 32, 29, 188, 105, 86, 192, 233, 33, 156, 251, 192, 248, 70, 170, 164, 253, 248, 78, 248, 3, 126, 79])
		static var salt_masterpass_getcodes_private = Crypto.Bytes(given: [65, 67, 8, 45, 88, 9, 203, 142, 29, 60, 70, 182, 173, 66, 217, 249, 128, 168, 5, 21, 117, 51, 69, 164, 210, 5, 155, 93, 103, 85, 1, 146])
		static var salt_pass = Crypto.Bytes(given: [242, 197, 49, 48, 149, 36, 162, 34, 238, 52, 97, 46, 26, 80, 247, 231, 47, 104, 62, 72, 197, 39, 249, 46, 69, 188, 189, 102, 43, 186, 92, 81])
		static var salt_getdata = Crypto.Bytes(given: [147, 84, 205, 167, 29, 57, 13, 247, 94, 178, 203, 82, 226, 171, 44, 62, 0, 149, 4, 143, 7, 250, 184, 115, 182, 9, 213, 62, 28, 22, 94, 59])
	}
	
	class var code_user: String? {
		get {return _code_user }
		set(new_code_user) {
			_code_user = new_code_user
			Funcs.ActivityObserver.sharedInstance().app_expires = NSDate().timeIntervalSince1970 + 30
		}
	}

	private class func getSchemaIdByMethod(method: String) -> Int? {
		var schema_id: Int? = nil
		switch(method){
			case "reg.status": schema_id = 0x0002
			case "reg.start": schema_id = 0x1001
			case "reg.confirm": schema_id = 0x1002
			case "device.create": schema_id = 0x1003
			case "device.confirm": schema_id = 0x1004
			case "device.auth": schema_id = 0x1005
            
			case "passwords.get": schema_id = nil
			case "passwords.getById": schema_id = 0x0001
			case "passwords.add": schema_id = 0x1101
			case "passwords.edit": schema_id = 0x1102
			case "passwords.delete": schema_id = 0x0001
			case "device.getList": schema_id = nil
			case "device.revoke": schema_id = 0x0002
			default:
				assert(false, "Function getSchemaIdByMethod: Unknown method \"\(method)\".")
		}
		return schema_id
	}

	class func call(
		method: String
	,	params: AnyObject
	,	callback: (([String: AnyObject]) -> Void)? = nil
	) -> Int {
		var url = API_path + method
		var answer_key: Crypto.Bytes? = nil
		var schema_id = getSchemaIdByMethod(method)
		var data_bytes = Crypto.Bytes()
		var req_bytes = Crypto.Bytes()
        
        switch(method){
			case "reg.status"
			, "reg.start"
			, "reg.confirm"
			, "device.create"
			, "device.confirm"
			, "device.auth"
			:
				assert(schema_id != nil, "Schema id can't be a nil in this case.")
				data_bytes = Schemas.utils.dataToSchemaBytes(schema_id!, input_data: params)
				var rsa_object: [String: AnyObject] = [ "hash": Crypto.Bytes() ]
				var rsa_object_chunks: [Crypto.Bytes] = []
				answer_key = Crypto.Bytes(randomWithLength: 32)
				var chunkLength = 128 - 11
				var data_toenc = Crypto.Bytes(randomWithLength: 16).append(answer_key!).append(data_bytes)
				//println(data_toenc.asArray())
				rsa_object["hash"] = data_toenc.getSHA1()
				for var i = 0; i < data_toenc.length; i+=chunkLength {
					var chunk = data_toenc.slice(i, length: chunkLength)
					//println("CHUNK : \(chunk.asArray())")
					rsa_object_chunks.append( Crypto.RSA.encrypt(chunk) )
				}
				rsa_object["chunks"] = rsa_object_chunks
				//print("> ")
				//println(rsa_object_chunks)
				req_bytes = Schemas.utils.dataToSchemaBytes(0x1000, input_data: rsa_object)
			default:
				var data_enc = Crypto.Cryptoblender.encrypt(schema_id == nil ? Crypto.Bytes() : Schemas.utils.dataToSchemaBytes(schema_id!, input_data: params), withKey: session_key)
				req_bytes = Crypto.Bytes(fromHexString: Storage.get("device_id") as! String).concat(data_enc)
		}
		println("REQUEST TO \(method)")
        //println("POST DATA: \( req_bytes.asArray() )")
		
		var postData: NSData = req_bytes.toNSData()
		var session = NSURLSession.sharedSession()
        var request: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = "POST"
        request.HTTPBody = postData
		
		UIApplication.sharedApplication().networkActivityIndicatorVisible = true
		var task = session.dataTaskWithRequest(request, completionHandler: { data, _response, error -> Void in
			dispatch_async(dispatch_get_main_queue(), {
				UIApplication.sharedApplication().networkActivityIndicatorVisible = false
				if let response = _response as? NSHTTPURLResponse {
					let rdata_bytes = Crypto.Bytes(fromNSData: data!)
					//println("rdata_bytes : \(rdata_bytes)")
					var rdata_bytes_dec = Crypto.Bytes()
					var rdata: AnyObject = ""
					if let contentType = response.allHeaderFields["Content-Type"] as? String {
						var contentTypeExt: String = contentType.componentsSeparatedByString("; ").last!
						switch contentTypeExt {
							case "plain":
								rdata = Schemas.utils.schemaBytesToData(rdata_bytes_dec)
							case "encrypted":
								if answer_key != nil
								{
									rdata_bytes_dec = Crypto.Cryptoblender.decrypt(rdata_bytes, withKey: answer_key!)
								}
								else
								{
									rdata_bytes_dec = Crypto.Cryptoblender.decrypt(rdata_bytes, withKey: session_key)
								}
								rdata = Schemas.utils.schemaBytesToData(rdata_bytes_dec)
							default:
								assert(false, "Invalid contentTypeExt: '\(contentTypeExt)'.")
						}
						//println(rdata)
						var rdata_code = rdata["code"] as! Int
						switch rdata_code {
							case 0:
								if method == "device.auth" {
									session_key = rdata["data"] as! Crypto.Bytes
								}
								else if method == "reg.confirm" {
									if let rdata_data = rdata["data"] as? [String: AnyObject]
									{
										session_key = rdata_data["session_key"] as! Crypto.Bytes
									}
								}
							
							case 603, 605:
								Storage.clear()
								Funcs.message("К сожалению, это устройство больше не имеет доступа к PSSWD. Пройдите авторизацию с мастер-паролем заново.", callback: { (index: Int) -> Void in
									var vc = Funcs.storyboard.instantiateViewControllerWithIdentifier("AuthEmailVC") as! UITableViewController
									Funcs.navigationController!.setViewControllers([ vc ], animated: false)
								})
								return
							
							default: break
						}
						if callback != nil {
							if let rdata_asDict = rdata as? [String: AnyObject] {
								callback!(rdata_asDict)
							}
						}
					}
				}
			})
			/*
			if error == nil {
				if data != nil {
					let rdata_bytes = Crypto.Bytes(fromNSData: data!)
					var rdata_bytes_dec = Crypto.Bytes()
					
					if answer_key != nil {
						rdata_bytes_dec = Crypto.cryptoblender.decrypt(rdata_bytes, withKey: answer_key!)
					}
					else {
						rdata_bytes_dec = Crypto.cryptoblender.decrypt(rdata_bytes, withKey: session_key)
					}
					
					println(rdata_bytes)
				}
				else {
					println("data is nil")
				}
			}
			*/
		})
		task.resume()
		
        return 0
    }
	
	class func unknownCode(data: [String: AnyObject])
	{
		let code = data["code"] as! Int
		Funcs.message("Неизвестный код ответа.\nКод #\(code)")
		println(data)
	}
}