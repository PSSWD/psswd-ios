//
//  Fields.swift
//  psswd
//
//  Created by Daniil on 11.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

class Fields
{
	struct classVar {
		static var defaultFields: [String: AnyObject] = [:]
	}
	
	class func uniteFields(srv_fields: [[String: AnyObject]], data_fields: [[String: AnyObject]]) -> [[String: AnyObject]]
	{
		var _fields: [[String: AnyObject]] = []
		
		for v in srv_fields
		{
			var _v = v
			let v_type = v["type"] as! String
			if "_" != Array(v_type)[0]
			{
				var def = classVar.defaultFields[v_type] as! [String: AnyObject]
				for (k2, v2) in v { def[k2] = v2 }
				_v = def
			}
			
			var existsFields = getByType(data_fields, type: v_type)
			if (nil != existsFields && v["editable"] as? Bool != false)
			{
				_v["value"] = existsFields!["value"]
			}
			
			_v["default"] = true
			
			_fields.append(_v)
		}
		
		for v in data_fields
		{
			if nil == getByType(_fields, type: v["type"] as! String)
			{
				_fields.append(v)
			}
		}
		
		return _fields
	}
	
	class func getByType(list: [ [String: AnyObject] ], type: String) -> [String: AnyObject]?
	{
		var _field: [String: AnyObject]? = nil
		
		for v in list
		{
			if v["type"] as! String == type
			{
				_field = v
				break
			}
		}
		
		return _field
	}
}
