//
//  Funcs.swift
//  psswd
//
//  Created by Daniil on 06.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

import UIKit
import Foundation

class Funcs
{
	class var storyboard: UIStoryboard { return UIStoryboard(name: "Main", bundle: nil) }
	class var navigationController: UINavigationController?
	{
		/*for el_window in UIApplication.sharedApplication().windows {
			println(el_window)
			println(el_window.rootViewController)
		}*/
		//println(UIApplication.sharedApplication().windows[0].rootViewController)
		//println(UIApplication.sharedApplication().windows)
		var el = UIApplication.sharedApplication().windows[0].rootViewController
		if let nc = el as? UINavigationController {
			return nc
		}
		else
		{
			return nil
		}
	}
	class func getStartupPasscodeScreen() -> SystemPasscodeVC
	{
		var vc = storyboard.instantiateViewControllerWithIdentifier("SystemPasscodeVC") as! SystemPasscodeVC
		
		vc.topTitle = "Введите пароль"
		
		//vc.buttonLeftTitle = "Забыли?"
		
		vc.buttonRightTitle = "Выйти"
		vc.buttonRightAction = { () -> Void in
			
		}
		
		vc.onSubmit = { (code_user: String) -> Void in
			var pass = Crypto.Bytes(fromString: code_user)
				.append( Storage.getBytes("code_client")! )
				.append( Storage.getBytes("code_client_pass")! )
				.append( API.constants.salt_pass )
				.getSHA1()
			var requestParams = [
				"device_id": Storage.getString("device_id")!,
				"pass": pass
			] as [String: AnyObject]

			API.call("device.auth", params: requestParams, callback: { rdata in
				let code = rdata["code"] as! Int
				
				switch code {
					case 0:
						API.code_user = code_user
					
						var vc = self.storyboard.instantiateViewControllerWithIdentifier("MainPassListVC") as! UITableViewController
						self.navigationController!.setViewControllers([ vc ], animated: false)
					case 606:
						var auth_attempts = rdata["data"] as! Int
						vc.clear()
						vc.shakeDots()
						if 1 == auth_attempts {
							Funcs.message("Обратите внимание, что у вас осталась последняя попытка ввода пароля.\nЕсли вы введёте неверный пароль ещё раз, приложение на этом устройстве будет заблокировано.")
						}
					case 607:
						Storage.clear()
						API.code_user = nil
						Funcs.message("Вы несколько раз подряд ввели неверный пароль. В целях безопасности мы заблокировали приложение на этом устройстве. Для разблокировки пройдите авторизацию заново.", callback: { index in
							var vc = self.storyboard.instantiateViewControllerWithIdentifier("AuthEmailVC") as! UITableViewController
							self.navigationController!.setViewControllers([ vc ], animated: false)
						})
					default:
						API.unknownCode(rdata)
				}
			})
		}
		
		return vc
	}
	
	private class UIBAlertView: UIAlertView, UIAlertViewDelegate {
		var callback: ((Int) -> Void)? = nil
		override func show() {
			super.show()
			self.delegate = self
		}
		func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
			println(buttonIndex)
			if nil != callback { callback!(buttonIndex) }
		}
	}
	class func message(msg_text: String, callback: (Int) -> Void = { index in }){
		var alert = UIBAlertView(title: "", message: msg_text, delegate: nil, cancelButtonTitle: "OK")
		alert.callback = callback
		alert.show()
	}
	class func message(title: String, msg_text: String, buttons: [String], callback: (Int) -> Void = { index in }){
		var alert = UIBAlertView(title: title, message: msg_text, delegate: nil, cancelButtonTitle: "Отмена")
		for title in buttons { alert.addButtonWithTitle(title) }
		alert.callback = callback
		alert.show()
	}
	class func message(msg_text: String, buttons: [String], callback: (Int) -> Void = { index in }){
		self.message("", msg_text: msg_text, buttons: buttons, callback: callback)
	}
	
	class func parseHexColorToInt(color: String) -> (red: UInt, green: UInt, blue: UInt)
	{
		var str = color
		if "#" == str.substringToIndex(advance(str.startIndex, 1))
		{
			str = str.substringFromIndex(advance(str.startIndex, 1))
		}
		
		var syms = Array(str)
		
		let red = (String(syms[0]) + String(syms[1])).withCString { strtoul($0, nil, 16) }
		let green = (String(syms[2]) + String(syms[3])).withCString { strtoul($0, nil, 16) }
		let blue = (String(syms[4]) + String(syms[5])).withCString { strtoul($0, nil, 16) }
		
		return (red: red, green: green, blue: blue)
	}
	class func parseHexColorToUIColor(color: String) -> UIColor
	{
		var colors = parseHexColorToInt(color)
		return UIColor(red: CGFloat(colors.red) / 255, green: CGFloat(colors.green) / 255, blue: CGFloat(colors.blue) / 255, alpha: 1)
	}
	
	class func parseTime(unixtime: Int) -> String
	{
		let months = ["янв", "фев", "мар", "апр", "мая", "июн", "июл", "авг", "сен", "окт", "ноя", "дек"]
		var str = ""
		let ts: NSDate = NSDate(timeIntervalSince1970: Double(unixtime))
		let components = NSCalendar.currentCalendar().components(
			NSCalendarUnit.CalendarUnitDay |
			NSCalendarUnit.CalendarUnitMonth |
			NSCalendarUnit.CalendarUnitYear |
			NSCalendarUnit.CalendarUnitHour |
			NSCalendarUnit.CalendarUnitMinute,
			fromDate: ts)
		str += "\(components.day) \(months[components.month - 1]) \(components.year)"
		str += " в \(components.hour):"
		str += components.minute < 10 ? "0" : ""
		str += "\(components.minute)"
		return str
	}
	
	class imageFolder
	{
		class func getPath() -> String
		{
			let path = (NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String) + "/loadedImages/"
			var fm = NSFileManager.defaultManager()
			if !fm.fileExistsAtPath(path)
			{
				fm.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil, error: nil)
			}
			return path
		}
		class func loadImage(urlString: String, callback: (UIImage?) -> Void)
		{
			var path = getPath()
			var hashName = Crypto.SHA1(urlString).toHex()// + "." + urlString.componentsSeparatedByString("/").last!.componentsSeparatedByString(".").last!
			//println(hashName)
			
			if NSFileManager.defaultManager().fileExistsAtPath(path + hashName)
			{
				var pic = UIImage(contentsOfFile: path + hashName)
				callback(pic)
			}
			else
			{
				//println("file \(hashName) not found")
				UIApplication.sharedApplication().networkActivityIndicatorVisible = true
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
					var pic_data = NSData(contentsOfURL: NSURL(string: urlString)!)
					if nil != pic_data {
						pic_data!.writeToFile(path + hashName, atomically: true)
						dispatch_async(dispatch_get_main_queue(), {
							UIApplication.sharedApplication().networkActivityIndicatorVisible = false
							callback( UIImage(data: pic_data!) )
						})
					}
				})
			}
		}
		class func clean()
		{
			var path = getPath()
			var fm = NSFileManager.defaultManager()
			
			let contents = fm.contentsOfDirectoryAtPath(path, error: nil)
			
			if nil == contents { return }
			
			for filename in contents as! [String]
			{
				let attrs = fm.attributesOfItemAtPath(path + filename, error: nil)
				if attrs != nil
				{
					let date = attrs![NSFileCreationDate] as! NSDate
					let interval = NSDate().timeIntervalSince1970 - date.timeIntervalSince1970
					//println("created \(interval / 60 / 60 / 24) days ago")
					
					if interval > 7 * 24 * 60 * 60 // one week
					{
						println("Image expires, deleting...")
						fm.removeItemAtPath(path + filename, error: nil)
					}
				}
			}
		}
		class func size() -> Int64
		{
			let path = getPath()
			let fm = NSFileManager.defaultManager()
			
			let contents = fm.contentsOfDirectoryAtPath(path, error: nil)
			
			if nil == contents { return -1 }
			
			var size: Int64 = 0
			for filename in contents as! [String]
			{
				let attrs = fm.attributesOfItemAtPath(path + filename, error: nil)
				let fileSize = attrs![NSFileSize] as! NSNumber
				size += Int(fileSize)
			}
			return size
		}
		class func removeAll()
		{
			var path = getPath()
			var fm = NSFileManager.defaultManager()
			
			let contents = fm.contentsOfDirectoryAtPath(path, error: nil)

			if nil == contents { return }
			
			for filename in contents as! [String]
			{
				fm.removeItemAtPath(path + filename, error: nil)
			}
		}
	}
	
	class jsonData
	{
		private class func getPath() -> String {
			let path = (NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String) + "/jsonData/"
			,	fm = NSFileManager.defaultManager()
			if !fm.fileExistsAtPath(path)
			{
				fm.createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil, error: nil)
			}
			return path
		}
		class func read(name: String) -> AnyObject
		{
			var path: String = getPath() + "\(name).json"
			
			if !NSFileManager.defaultManager().fileExistsAtPath(path)
			{
				path = NSBundle.mainBundle().pathForResource(name, ofType: "json")!
				//println("reading \(name) from mainBundle")
			}
			else
			{
				//println("reading \(name) from jsonData folder")
			}

			var parsedData: AnyObject? = NSJSONSerialization.JSONObjectWithData(NSData(contentsOfFile: path)!, options: nil, error: nil)
			if nil == parsedData
			{
				println("Can't parse \(name).")
				return false
			}
			else
			{
				return parsedData!
			}
		}
		class func update(name: String, callback:() -> Void)
		{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
				let response = NSData(contentsOfURL: NSURL(string: "http://api.psswd.co/data/\(name)")!)
				if nil == response { return }
				dispatch_async(dispatch_get_main_queue(), {
					let parsedData: AnyObject? = NSJSONSerialization.JSONObjectWithData(response!,
						options: nil,
						error: nil)
					if nil == parsedData
					{
						println("Can't parse \(name).")
					}
					else
					{
						let json = parsedData! as? [String: AnyObject]
						if nil != json
						{
							let code = json!["code"] as! Int
							if code == 0
							{
								let json_data = json!["data"] as! [String: AnyObject]
								let path = self.getPath() + "\(name).json"
								let data: NSData = NSJSONSerialization.dataWithJSONObject(json_data, options: nil, error: nil)!
								data.writeToFile(path, atomically: true)
								callback()
							}
						}
					}
				})
			})
		}
	}
	
	class func observePasteboard() -> Bool
	{
		var pasteboard_content = UIPasteboard.generalPasteboard().string
		
		if nil != pasteboard_content
		{
			let saved_pasteboard_content = Storage.getString("saved_pasteboard_content")
			let saved_pasteboard_expires = Storage.getInt("saved_pasteboard_expires")
			
			if nil != saved_pasteboard_content && nil != saved_pasteboard_expires {
				
				let ts = Int(NSDate().timeIntervalSince1970)
				
				println("\(saved_pasteboard_expires! - ts)s to clear")
				
				if ts >= saved_pasteboard_expires
				{
					Storage.remove("saved_pasteboard_content")
					Storage.remove("saved_pasteboard_expires")

					if saved_pasteboard_content == pasteboard_content
					{
						UIPasteboard.generalPasteboard().string = ""
						println("pasteboard cleared")
					
						return true
					}
				}
			}
		}
		
		return false
	}
	
	class ActivityObserver
	{
		private class var _sharedInstance : ActivityObserver {
			struct Static {
				static let instance : ActivityObserver = ActivityObserver()
			}
			return Static.instance
		}
		class func sharedInstance() -> ActivityObserver { return _sharedInstance }
		init()
		{
			gesture()
			NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("checkApp"), userInfo: nil, repeats: true)
		}
		
		var app_expires: Double = 0
		var enabled = true
		func gesture()
		{
			if !enabled { return }
			//println("gesture \(MTRandom().randomDouble())")
			app_expires = NSDate().timeIntervalSince1970 + 30
		}
		@IBAction func checkApp()
		{
			if nil == API.code_user { return }
			
			//println("\(app_expires - NSDate().timeIntervalSince1970)s until lock")
			
			if NSDate().timeIntervalSince1970 >= app_expires
			{
				Funcs.lockApp()
			}
		}
	}
	
	class func lockApp()
	{
		if nil == API.code_user { return }

		API.code_user = nil
		session_key = Crypto.Bytes()
		
		self.navigationController!.setViewControllers([ self.getStartupPasscodeScreen() ], animated: false)
	}
	
	class appOverlay
	{
		class func show()
		{
			let vc = Funcs.storyboard.instantiateViewControllerWithIdentifier("BlockVC") as! UIViewController
			vc.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
			Funcs.ActivityObserver.sharedInstance().enabled = false
			Funcs.navigationController?.presentViewController(vc, animated: true, completion: nil)
		}
		class func hide()
		{
			var vc = Funcs.navigationController?.presentedViewController
			if nil == vc { return }
			if vc?.view.tag == 1310
			{
				vc?.dismissViewControllerAnimated(true, completion: {
					Funcs.ActivityObserver.sharedInstance().enabled = true
				})
			}
		}
	}
}
