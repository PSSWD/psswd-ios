//
//  MainSettingsVC.swift
//  psswd
//
//  Created by Daniil on 22.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

import UIKit
import Foundation

class MainSettingsVC: UITableViewController, UITableViewDelegate, UIActionSheetDelegate
{
	override func viewDidLoad()
	{
		super.viewDidLoad()
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		switch (indexPath.section, indexPath.row)
		{
		case (1, 1):
			//println("Purge cache")
			Funcs.imageFolder.removeAll()
			self.tableView.reloadData()
		case (2, 0):
			//println("Log out")
			var menu = UIActionSheet()
			menu.delegate = self
			menu.addButtonWithTitle("Выйти из аккаунта")
			menu.destructiveButtonIndex = 0
			menu.addButtonWithTitle("Отмена")
			menu.cancelButtonIndex = 1
			menu.showInView(self.view)
		default: break
		}
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}
	
	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		if (indexPath.section == 1 && indexPath.row == 0) // cache size
		{
			let cacheSize = Funcs.imageFolder.size()
			//println(cacheSize)
			var textSize = "\(cacheSize) Б"
			switch Double(cacheSize)
			{
			case 0 ..< 1024:
				textSize = "\(cacheSize) Б"
			case 1024 ..< pow(1024, 2):
				var kb = Float64(cacheSize) / 1024
				textSize = (NSString(format: "%.2f", kb) as String) + " КБ"
			case pow(1024, 2) ..< pow(1024, 3):
				var mb = Float64(cacheSize) / pow(1024, 2)
				textSize = (NSString(format: "%.2f", mb) as String) + " МБ"
			case pow(1024, 3) ..< pow(1024, 4):
				var gb = Float64(cacheSize) / pow(1024, 3)
				textSize = (NSString(format: "%.2f", gb) as String) + " ГБ"
			default: break
			}
			(cell.contentView.subviews[1] as! UILabel).text = textSize
		}
	}
	func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
		if 0 != buttonIndex { return }
		API.call("device.revoke", params: "", callback: { rdata in
			let code = rdata["code"] as! Int
			switch code {
			case 0:
				API.code_user = nil
				Storage.clear()
				session_key = Crypto.Bytes()
				
				var vc = self.storyboard?.instantiateViewControllerWithIdentifier("AuthEmailVC") as! UITableViewController
				self.navigationController?.setViewControllers([ vc ], animated: false)
			default:
				API.unknownCode(rdata)
			}
		})
	}
}
