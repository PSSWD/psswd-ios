//
//  MainPassListVC.swift
//  psswd
//
//  Created by Daniil on 06.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

import UIKit
import Foundation

class MainPassListVC: UITableViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate
{
	var pass_info: [ [String: AnyObject] ] = []
	var pass_info_sorted: [ [String: AnyObject] ] = []
	
	struct rowSizes {
		static var height = 60
		static var padding = (8, 8) // x, y
		static var contentHeight = height - 2 * padding.1 // 44
		static var imageWidth = contentHeight
		static var labelWidth = 0
		static var titleOffset = (2 * padding.0 + imageWidth, padding.1) // x, y
		static var titleHeight = 24
		static var subtitleOffset = (2 * padding.0 + imageWidth, padding.1 + titleHeight) // x, y
		static var subtitleHeight = contentHeight - titleHeight
	}

	override func viewDidLoad()
	{
		super.viewDidLoad()

		rowSizes.labelWidth = Int(self.tableView.frame.size.width) - rowSizes.titleOffset.0 - rowSizes.padding.0
		
		self.refreshControl?.addTarget(self, action: "loadData", forControlEvents: UIControlEvents.ValueChanged)
		
		loadData()
	}
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		var image = UIImage(named: "ios7-gear-outline")
		let newSize = CGSizeMake(22, 22)
		UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
		image?.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
		var newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		self.navigationItem.leftBarButtonItem?.image = newImage
		self.navigationItem.leftBarButtonItem?.title = ""
	}
	
	func loadData()
	{
		API.call("passwords.get", params: 0, callback: { rdata in
			let code = rdata["code"] as Int
			switch code {
			case 0:
				var key = Crypto.Bytes(fromString: API.code_user!)
					.append( Storage.getBytes("code_client")! )
					.append( Storage.getBytes("code_client_getdata")! )
					.append( API.constants.salt_getdata )
					.getSHA1()
				
				if let rdata_data = rdata["data"] as? [ [String: AnyObject] ]
				{
					self.pass_info = []
					for el in rdata_data
					{
						let bytes = el["info_enc"] as Crypto.Bytes
						let bytes_decrypted = Crypto.Cryptoblender.decrypt(bytes, withKey: key)
						var pass_info_one = el
						pass_info_one["info"] = Schemas.utils.schemaBytesToData( bytes_decrypted )
						pass_info_one.removeValueForKey("info_enc")
						self.pass_info.append(pass_info_one)
					}
					self.pass_info = sorted(self.pass_info, { (obj1: [String: AnyObject], obj2: [String: AnyObject]) -> Bool in
						let obj1_info = obj1["info"] as [String: AnyObject]
						var obj1_title = obj1_info["title"] as String
						if "" == obj1_title {
							let srv = Services.getById(obj1_info["service_id"] as String)
							obj1_title = srv["title"] as String
						}
						
						let obj2_info = obj2["info"] as [String: AnyObject]
						var obj2_title = obj2_info["title"] as String
						if "" == obj2_title {
							let srv = Services.getById(obj2_info["service_id"] as String)
							obj2_title = srv["title"] as String
						}
						
						return obj1_title.lowercaseString < obj2_title.lowercaseString
					})
					//println(self.pass_info)
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
		return tableView == self.searchDisplayController!.searchResultsTableView ? pass_info_sorted.count : pass_info.count
	}
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
	{
		return CGFloat(rowSizes.height)
	}
	
	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
	{
		tableView.separatorInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
		tableView.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
		cell.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	{
		var cell = UITableViewCell(style: .Default, reuseIdentifier: nil)
		,	data: [String: AnyObject] = tableView == self.searchDisplayController!.searchResultsTableView ? pass_info_sorted[indexPath.row] : pass_info[indexPath.row]
		,	data_info = data["info"] as [String: AnyObject]
		,	srv = Services.getById(data_info["service_id"] as String)
		,	srv_id = srv["id"] as String
		
		if let srv_icon = srv["icon"] as? Int
		{
			let gradient_colors = Services.classVar.gradients[srv_icon]
			var view_logo = UIView(frame: CGRectMake(
				CGFloat(rowSizes.padding.0),
				CGFloat(rowSizes.padding.1),
				CGFloat(rowSizes.imageWidth),
				CGFloat(rowSizes.imageWidth)
				))
			
			let gradient : CAGradientLayer = CAGradientLayer()
			gradient.frame = view_logo.bounds
			let color_field_top = Funcs.parseHexColorToUIColor(gradient_colors[0]).CGColor
			let color_field_bottom = Funcs.parseHexColorToUIColor(gradient_colors[1]).CGColor
			gradient.colors = [color_field_top, color_field_bottom]
			view_logo.layer.insertSublayer(gradient, atIndex: 0)
			
			var view_logo_label = UILabel(frame: CGRectMake(
				CGFloat(0),
				CGFloat(0),
				CGFloat(rowSizes.imageWidth),
				CGFloat(rowSizes.imageWidth)
				))
			view_logo_label.textColor = Funcs.parseHexColorToUIColor(gradient_colors[2])
			view_logo_label.text = String( Array(srv["title"] as String)[0] )
			view_logo_label.textAlignment = NSTextAlignment.Center
			view_logo_label.font = view_logo_label.font.fontWithSize(25)
			view_logo.addSubview(view_logo_label)
			
			cell.contentView.addSubview(view_logo)
		}
		else if "default" != srv_id
		{
			let srv_icon = srv["icon"] as String
			var view_logo = UIImageView(frame: CGRectMake(
				CGFloat(rowSizes.padding.0),
				CGFloat(rowSizes.padding.1),
				CGFloat(rowSizes.imageWidth),
				CGFloat(rowSizes.imageWidth)
				))
			Funcs.imageFolder.loadImage(srv_icon == "default" ? Services.getDefaultIconPath(srv_id) : srv_icon, callback: { view_logo_image in
				view_logo.image = view_logo_image
			})
			cell.contentView.addSubview(view_logo)
		}
		
		var view_title = UILabel(frame: CGRectMake(
			CGFloat(rowSizes.titleOffset.0),
			CGFloat(rowSizes.titleOffset.1),
			CGFloat(rowSizes.labelWidth),
			CGFloat(rowSizes.titleHeight)
			))
		let view_title_text = data_info["title"] as String
		view_title.text = view_title_text == "" ? srv["title"] as String : view_title_text
		view_title.font = view_title.font.fontWithSize(20)
		cell.contentView.addSubview(view_title)

		var view_subtitle = UILabel(frame: CGRectMake(
			CGFloat(rowSizes.subtitleOffset.0),
			CGFloat(rowSizes.subtitleOffset.1),
			CGFloat(rowSizes.labelWidth),
			CGFloat(rowSizes.subtitleHeight)
			))
		view_subtitle.text = data_info["subtitle"] as? String
		view_subtitle.font = view_subtitle.font.fontWithSize(15)
		view_subtitle.textColor = UIColor(red: 0x88/0xff, green: 0x88/0xff, blue: 0x88/0xff, alpha: 1)
		cell.contentView.addSubview(view_subtitle)
		
		return cell
	}
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	{
		tableView.deselectRowAtIndexPath(indexPath, animated:true)

		var data: [String: AnyObject] = tableView == self.searchDisplayController!.searchResultsTableView ? pass_info_sorted[indexPath.row] : pass_info[indexPath.row]
		
		var vc = self.storyboard?.instantiateViewControllerWithIdentifier("MainPassDetailVC") as MainPassDetailVC
		vc.pass_id = data["pass_id"] as Int
		self.navigationController!.pushViewController(vc, animated: true)
	}
	
	func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool
	{
		self.filterContentForSearchText(searchString)
		return true
	}
	func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchScope searchOption: Int) -> Bool
	{
		self.filterContentForSearchText(self.searchDisplayController!.searchBar.text)
		return true
	}
	
	func filterContentForSearchText(query: String)
	{
		pass_info_sorted = []
		
		if "" == query {
			pass_info_sorted = pass_info
			return
		}
		
		for data: [String: AnyObject] in pass_info
		{
			var data_info = data["info"] as [String: AnyObject]
			,	data_info_title = data_info["title"] as String
			,	srv = Services.getById(data_info["service_id"] as String)
			,	relev = -1
			,	keywords = nil == srv["tags"] ? [] : srv["tags"] as [String]
			keywords.append(data_info_title)
			keywords.append(data_info["subtitle"] as String)
			keywords = keywords.filter({ NSString(string: $0).rangeOfString(query).location != NSNotFound })
			//println(keywords)
			
			if keywords.count == 0 { continue }
			
			for i: String in keywords
			{
				relev = NSString(string: i).rangeOfString(query).location
				//println("finded substring '\(query)' in '\(i)': result \(relev)")
			}
			//if -1 == relev { continue }
			
			var new_data = data
			new_data["index"] = relev
			pass_info_sorted.append(new_data)
		}
		//println(pass_info_sorted)

		self.pass_info_sorted = sorted(self.pass_info_sorted, { (obj1: [String: AnyObject], obj2: [String: AnyObject]) -> Bool in
			let obj1_index = obj1["index"] as Int
			let obj2_index = obj2["index"] as Int
			
			return obj1_index < obj2_index
		})
		//println(pass_info_sorted)
	}
}
