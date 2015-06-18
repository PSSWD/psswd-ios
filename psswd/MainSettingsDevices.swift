//
//  MainSettingsDevices.swift
//  psswd
//
//  Created by Daniil on 22.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

import UIKit

class MainSettingsDevices: UITableViewController, UITableViewDelegate, UIActionSheetDelegate
{
	private var isReady = false
	private var devices: [[String: AnyObject]] = []
	
	private var selectedRow = -1
	private var currentDevice = -1

	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.refreshControl?.addTarget(self, action: "loadData", forControlEvents: UIControlEvents.ValueChanged)
		
		loadData()
	}
	
	func loadData(){
		API.call("device.getList", params: 0, callback: { rdata in
			let code = rdata["code"] as! Int
			switch code {
			case 0:
				self.devices = rdata["data"] as! [[String: AnyObject]]
				
				self.isReady = true
				self.tableView.reloadData()
				break
			default:
				API.unknownCode(rdata)
			}
			
			self.refreshControl?.endRefreshing()
		})
	}
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
	{
		return 77
	}
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if !isReady { return 1 }
		return devices.count
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		if !isReady { return UITableViewCell(style: .Default, reuseIdentifier: "loading") }

		var cell = UITableViewCell(style: .Subtitle, reuseIdentifier: nil)
		//cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
		
		let data = devices[indexPath.row]

		var title = data["app_title"] as! String
		let app_about = data["app_about"] as! String
		if "" != app_about { title += " (\(app_about))" }
		cell.textLabel?.text = title

		var detail = Funcs.parseTime(data["session_create"] as! Int) + "\n"
		if Crypto.SHA1("S6TXiGI?.u39a.ck48K8Hoq44wOtMVQu" + Storage.getString("device_id")!).toHex() == data["device_id_hash"] as! String
		{
			self.currentDevice = indexPath.row
			detail += "Вы сейчас смотрите на него"
		}
		else
		{
			detail += data["session_ip"] as! String
		}
		cell.detailTextLabel?.text = detail
		cell.detailTextLabel?.textColor = UIColor.grayColor()
		cell.detailTextLabel?.font = cell.detailTextLabel?.font.fontWithSize(13)
		cell.detailTextLabel?.numberOfLines = 2

		return cell
	}
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		if indexPath.row == self.currentDevice { return }
		self.selectedRow = indexPath.row
		
		var menu = UIActionSheet()
		menu.delegate = self
		menu.addButtonWithTitle("Отозвать доступ")
		menu.destructiveButtonIndex = 0
		menu.addButtonWithTitle("Отмена")
		menu.cancelButtonIndex = 1
		menu.showInView(self.view)
	}
	func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
		if 0 != buttonIndex { return }
		Funcs.message("Вы уверены?", msg_text: "Доступ этого приложения к вашему аккаунту будет отозван.", buttons: ["Отозвать доступ"], callback: { index in

			if 1 != index { return }

			let data = self.devices[self.selectedRow]
			
			API.call("device.revoke", params: data["device_id_hash"] as! String, callback: { rdata in
				let code = rdata["code"] as! Int
				switch code {
				case 0:
					Funcs.message("Доступ успешно отозван. Приложение больше не имеет доступа к этому аккаунту.")
					self.loadData()
				default:
					API.unknownCode(rdata)
				}
			})
		})
	}
}
