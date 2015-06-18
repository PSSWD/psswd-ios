//
//  MainPassDetail.swift
//  psswd
//
//  Created by Daniil on 09.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

import UIKit

class MainPassDetailVC: UITableViewController, UITableViewDelegate, UIActionSheetDelegate
{
	var pass_id = 0
	
	private var isReady = false
	
	private var pass_info: [String: AnyObject] = [:]
	private var pass_data: [String: AnyObject] = [:]
	
	private var srv_id = ""
	private var srv: [String: AnyObject] = [:]
	
	private var pass_unitedFields: [ [String: AnyObject] ] = []
	
	private var pass_title = ""
	
	private var design_titleEmpty = false
	private var design_coverNextGen = false
	
	private var selectedIndexPath: NSIndexPath = NSIndexPath(index: 0)
	
	private var hiddenPass = "●●●●●●●●●●"

	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		//self.tableView.tableFooterView?.backgroundColor = UIColor.whiteColor()
		self.tableView.tableFooterView = UIView(frame: CGRectZero)
		
		self.refreshControl?.addTarget(self, action: "loadData", forControlEvents: UIControlEvents.ValueChanged)
		
		loadData()
	}
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		self.tableView.reloadData()
	}
	
	func loadData()
	{
		API.call("passwords.getById", params: pass_id, callback: { rdata in
			let code = rdata["code"] as! Int
			switch code {
			case 0:
				var key = Crypto.Bytes(fromString: API.code_user!)
					.append( Storage.getBytes("code_client")! )
					.append( Storage.getBytes("code_client_getdata")! )
					.append( API.constants.salt_getdata )
					.getSHA1()
				
				if let rdata_data = rdata["data"] as? [String: AnyObject]
				{
					let info_bytes_enc = rdata_data["info_enc"] as! Crypto.Bytes
					let info_bytes_dec = Crypto.Cryptoblender.decrypt(info_bytes_enc, withKey: key)
					self.pass_info = Schemas.utils.schemaBytesToData( info_bytes_dec ) as! [String: AnyObject]
					//println(self.pass_info)
					
					let data_bytes_enc = rdata_data["data_enc"] as! Crypto.Bytes
					let data_bytes_dec = Crypto.Cryptoblender.decrypt(data_bytes_enc, withKey: key)
					self.pass_data = Schemas.utils.schemaBytesToData( data_bytes_dec ) as! [String: AnyObject]
					//println(self.pass_data)
					
					self.srv_id = self.pass_info["service_id"] as! String
					self.srv = Services.getById(self.srv_id)
					//println(self.srv)
					
					self.pass_unitedFields = Fields.uniteFields(self.srv["fields"] as! [ [String: AnyObject] ], data_fields: self.pass_data["fields"]  as! [ [String: AnyObject] ])
					//println(self.pass_unitedFields)
					
					let view_title_text = self.pass_info["title"] as! String
					self.pass_title = view_title_text == "" ? self.srv["title"] as! String : view_title_text
					
					if ("default" == self.srv_id || nil != self.srv["icon"] as? Int)
					{
						self.design_titleEmpty = true
					}
					if let iconPadColor = self.srv["iconPadColor"] as? String
					{
						if iconPadColor != "#ffffff"
						{
							self.design_coverNextGen = true
						}
					}
					
					self.isReady = true
					
					self.tableView.reloadData()
					self.refreshControl?.endRefreshing()
				}
			default:
				API.unknownCode(rdata)
			}
		})
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return 1 + self.pass_unitedFields.count
	}
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
	{
		if !self.isReady { return 9999 }

		switch indexPath.row
		{
		case 0:
			if design_titleEmpty
			{
				return 62
			}
			else
			{
				return 150
			}
		default:
			return 65
		}
	}
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		var cell = UITableViewCell(style: .Default, reuseIdentifier: nil)
		cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y, cell.frame.size.width, self.tableView(tableView, heightForRowAtIndexPath: indexPath))
		cell.contentView.frame = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)
		
		if !self.isReady { return cell }
		
		switch indexPath.row
		{
		case 0:
			cell.userInteractionEnabled = false
			
			var view_title_text = UILabel(frame: CGRectMake(16, 16, cell.frame.width - 32, 25))
			let view_title_text_text = pass_info["title"] as! String
			view_title_text.text = view_title_text_text == "" ? srv["title"] as! String : view_title_text_text
			view_title_text.font = UIFont(name: "HelveticaNeue-Light", size: 21)
			
			//view_title_text.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.25)
			
			if design_titleEmpty
			{
				view_title_text.textColor = UIColor.blackColor()
				cell.contentView.addSubview(view_title_text)
			}
			else
			{
				cell.separatorInset = UIEdgeInsetsMake(0, cell.bounds.size.width, 0, 0)

				view_title_text.textColor = UIColor.whiteColor()

				var view_title_logo = UIImageView()

				if let iconPadColor = srv["iconPadColor"] as? String
				{
					// nextGen cover
					var iconPadColor_uicolor = Funcs.parseHexColorToUIColor(iconPadColor)
					cell.contentView.backgroundColor = iconPadColor_uicolor
					let height_for_logo = (cell.frame.height - (view_title_text.frame.size.height + 16))
					let view_title_logo_width = height_for_logo * 0.9
					view_title_logo.frame = CGRectMake(
						(cell.frame.width - view_title_logo_width) / 2,
						(height_for_logo - view_title_logo_width) / 2,
						view_title_logo_width,
						view_title_logo_width)
					cell.contentView.addSubview(view_title_logo)
					
					if let iconPadTextColor = srv["iconPadTextColor"] as? String
					{
						view_title_text.textColor = Funcs.parseHexColorToUIColor(iconPadTextColor)
					}
					else
					{
						UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
					}
					
					var bar = self.navigationController!.navigationBar
					bar.tintColor = view_title_text.textColor
					bar.barTintColor = iconPadColor_uicolor
					bar.translucent = false
					bar.setBackgroundImage(UIImage(), forBarPosition: UIBarPosition.Any, barMetrics: UIBarMetrics.Default)
					bar.shadowImage = UIImage()
					self.tableView.backgroundColor = iconPadColor_uicolor
					self.refreshControl?.backgroundColor = iconPadColor_uicolor
					self.refreshControl?.tintColor = view_title_text.textColor.colorWithAlphaComponent(0.75)
					
					view_title_text.frame = CGRectMake(
						view_title_text.frame.origin.x,
						cell.contentView.frame.height - 16 - view_title_text.frame.size.height,
						view_title_text.frame.size.width,
						view_title_text.frame.size.height)
					cell.contentView.addSubview(view_title_text)
				}
				else
				{
					let view_title_logo_width = cell.frame.width
					view_title_logo.frame = CGRectMake(
						0,
						(cell.frame.height - view_title_logo_width) / 2,
						view_title_logo_width,
						view_title_logo_width)
					cell.clipsToBounds = true
					cell.contentView.addSubview(view_title_logo)
					
					var view_title_shadow = UIView(frame: CGRectMake(
						0,
						cell.contentView.frame.height - 16 - view_title_text.frame.size.height - 16,
						view_title_text.frame.size.width + 32,
						view_title_text.frame.size.height + 32))
					//view_title_shadow.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.33)
					let gradient : CAGradientLayer = CAGradientLayer()
					gradient.frame = view_title_shadow.bounds
					gradient.colors = [
						UIColor.clearColor().CGColor,
						UIColor.blackColor().colorWithAlphaComponent(0.33).CGColor,
						UIColor.blackColor().colorWithAlphaComponent(0.75).CGColor
					]
					view_title_shadow.layer.insertSublayer(gradient, atIndex: 0)
					cell.contentView.addSubview(view_title_shadow)
					
					view_title_text.frame = CGRectMake(
						view_title_text.frame.origin.x,
						16,
						view_title_text.frame.size.width,
						view_title_text.frame.size.height)
					view_title_shadow.addSubview(view_title_text)
				}

				let srv_icon = srv["icon"] as! String
				var icon_url = srv_icon == "default" ? Services.getDefaultIconPath(srv_id) : srv_icon
				if nil != srv["iconBig"]
				{
					let srv_icon = srv["iconBig"] as! String
					icon_url = srv_icon == "default" ? Services.getDefaultIconBigPath(srv_id) : srv_icon
				}
				Funcs.imageFolder.loadImage(icon_url, callback: { image in
					if nil != self.srv["iconBig"] && nil != image
					{
						var height = view_title_logo.frame.size.height * 0.75
						var width = image!.size.width * height / image!.size.height
						var x = view_title_logo.frame.origin.x + view_title_logo.frame.size.width / 2 - width / 2
						var y = view_title_logo.frame.origin.y + view_title_logo.frame.size.height / 2 - height / 2
						view_title_logo.frame = CGRectMake(x, y, width, height)
					}
					view_title_logo.image = image
				})
			}
		case 1 ... self.pass_unitedFields.count:
			if (indexPath.row == self.pass_unitedFields.count && self.design_coverNextGen)
			{
				cell.separatorInset = UIEdgeInsetsMake(0, cell.bounds.size.width, 0, 0)
			}
			
			var data_field = self.pass_unitedFields[indexPath.row - 1]
			
			var view_title = UILabel(frame: CGRectMake(
				16,
				12,
				cell.contentView.frame.size.width - 32,
				15))
			//view_title.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.1)
			view_title.font = view_title.font.fontWithSize(14)
			view_title.textColor = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
			view_title.text = data_field["title"] as? String
			cell.contentView.addSubview(view_title)

			var view_value = UILabel(frame: CGRectMake(
				16,
				view_title.frame.origin.y + view_title.frame.size.height + 6,
				cell.contentView.frame.size.width - 32,
				20))
			//view_value.backgroundColor = UIColor.greenColor().colorWithAlphaComponent(0.1)
			view_value.font = view_value.font.fontWithSize(17)
			let data_field_value = data_field["value"] as? String
			if true == data_field["secure"] as? Bool
			{
				view_value.text = hiddenPass
				cell.contentView.tag = 1
			}
			else
			{
				view_value.text = data_field_value
				
				if "site_url" == data_field["type"] as! String
				{
					cell.contentView.tag = 2
				}
			}
			cell.contentView.addSubview(view_value)
		default: break
		}
		
		return cell
	}
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		tableView.deselectRowAtIndexPath(indexPath, animated:true)
		
		var contentView = tableView.cellForRowAtIndexPath(indexPath)!.contentView
		
		var menu = UIActionSheet()
		menu.delegate = self
		menu.tag = indexPath.row
		self.selectedIndexPath = indexPath
		menu.addButtonWithTitle("Скопировать")
		
		switch contentView.tag
		{
		case 0:
			// just copy
			break
		case 1:
			// password object
			let label = contentView.subviews[1] as! UILabel
			menu.addButtonWithTitle((label.text == hiddenPass ? "Показать" : "Скрыть") + " пароль")
		case 2:
			// go to url
			UIApplication.sharedApplication().openURL(NSURL(string: (contentView.subviews[1] as! UILabel).text!)!)
			return
		default: break
		}
		
		menu.addButtonWithTitle("Отмена")
		menu.cancelButtonIndex = menu.numberOfButtons - 1
		menu.showInView(self.view)
	}
	func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
		if buttonIndex == actionSheet.cancelButtonIndex { return }

		let contentView = tableView.cellForRowAtIndexPath(self.selectedIndexPath)!.contentView

		switch buttonIndex
		{
		case 0:
			var textToCopy = (contentView.subviews[1] as! UILabel).text!
			if contentView.tag == 1
			{
				var data_field = self.pass_unitedFields[self.selectedIndexPath.row - 1]
				textToCopy = data_field["value"] as! String
			}
			UIPasteboard.generalPasteboard().string = textToCopy
			
			let pasteboardTimeout = 5
			
			Storage.set(textToCopy, forKey: "saved_pasteboard_content")
			Storage.set(Int(NSDate().timeIntervalSince1970) + pasteboardTimeout, forKey: "saved_pasteboard_expires")
			var time = dispatch_time(DISPATCH_TIME_NOW, Int64((pasteboardTimeout + 1) * Int64(NSEC_PER_SEC)))
			dispatch_after(time, dispatch_get_main_queue(), {
				Funcs.observePasteboard()
				return
			})
		case 1:
			if contentView.tag == 1
			{
				var data_field = self.pass_unitedFields[self.selectedIndexPath.row - 1]
				let label = contentView.subviews[1] as! UILabel
				if label.text == hiddenPass
				{
					label.text = data_field["value"] as? String
					label.font = UIFont(name: "Courier", size: 17)
				}
				else
				{
					label.text = hiddenPass
					label.font = UIFont(name: "HelveticaNeue", size: 17)
				}
			}
		default: break
		}
	}
}
