//
//  Services.swift
//  psswd
//
//  Created by Daniil on 08.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

class Services
{
	struct classVar {
		static var services_list: [ [String: AnyObject] ] = []
		static var services_defaultIconPath = ""
		static var services_defaultIconBigPath = ""
		
		static var gradients: [ [String] ] = []
	}
	class func create(needUpdate: Bool = true)
	{
		if let data_services = Funcs.jsonData.read("services") as? [String: AnyObject]
		{
			if let parsedList = data_services["list"] as? [ [String: AnyObject] ]
			{
				classVar.services_list = parsedList
				//println(services_list)
			}
			if let defaultIconPath = data_services["defaultIconPath"] as? String
			{
				classVar.services_defaultIconPath = defaultIconPath
				//println(services_defaultIconPath)
			}
			if let defaultIconBigPath = data_services["defaultIconBigPath"] as? String
			{
				classVar.services_defaultIconBigPath = defaultIconBigPath
				//println(services_defaultIconBigPath)
			}
			if let defaultFields = data_services["defaultFields"] as? [String: AnyObject] {
				Fields.classVar.defaultFields = defaultFields
				//println(defaultFields)
			}
		}
		
		let data_gradients: AnyObject = Funcs.jsonData.read("gradients")
		if let parsedList = data_gradients as? [ [String] ] {
			classVar.gradients = parsedList
			//println(services_gradients)
		}
		
		if needUpdate
		{
			Funcs.jsonData.update("services", callback: {
				self.create(needUpdate: false)
			})
		}
	}
	
	class func getById(service_id: String) -> [String: AnyObject]
	{
		for el in classVar.services_list
		{
			if service_id == el["id"] as! String
			{
				return el
			}
		}
		return [:]
	}
	
	class func getDefaultIconPath(name: String) -> String {
		var com = classVar.services_defaultIconPath.componentsSeparatedByString("%service_id%")
		var res = "\(com[0])\(name)\(com[1])"
		return res
	}
	class func getDefaultIconBigPath(name: String) -> String {
		var com = classVar.services_defaultIconBigPath.componentsSeparatedByString("%service_id%")
		var res = "\(com[0])\(name)\(com[1])"
		return res
	}
}
