//
//  Storage.swift
//  psswd
//
//  Created by Daniil on 29.12.14.
//  Copyright (c) 2014 kirick. All rights reserved.
//

import Foundation

class Storage
{
	private class func defaults() -> NSUserDefaults
	{
		return NSUserDefaults.standardUserDefaults()
	}

	class func set(data: AnyObject, forKey: String)
	{
		defaults().setObject(data, forKey: forKey)
		defaults().synchronize()
	}
	class func setBytes(data: Crypto.Bytes, forKey: String)
	{
		set(data.toHex(), forKey: forKey)
	}

	class func get(key: String) -> AnyObject?
	{
		return defaults().objectForKey(key)
	}
	class func getInt(key: String) -> Int?
	{
		return defaults().integerForKey(key)
	}
	class func getString(key: String) -> String?
	{
		return defaults().stringForKey(key)
	}
	class func getBytes(key: String) -> Crypto.Bytes?
	{
		var str = getString(key)
		return nil == str ? nil : Crypto.Bytes(fromHexString: str!)
	}
	
	class func remove(key: String){
		defaults().removeObjectForKey(key)
	}
	class func clear(){
		for (key, value) in defaults().dictionaryRepresentation() {
			remove(key as! String)
		}
	}
}
