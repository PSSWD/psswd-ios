//
//  Schemas.swift
//  psswd
//
//  Created by Daniil on 21.12.14.
//  Copyright (c) 2014 kirick. All rights reserved.
//

import Foundation

class Schemas {
	struct classVar {
		static var list: [Int: AnyObject] = [:]
	}
	
	class func create(needUpdate: Bool = true) {
		if let parsedList = Funcs.jsonData.read("schemas") as? [String: AnyObject] {
			for (key, object) in parsedList {
				classVar.list[key.toInt()!] = object
			}
			//println(list)
		}
		else {
			println("Can't parse schemas.")
		}
		
		if needUpdate
		{
			Funcs.jsonData.update("schemas", {
				self.create(needUpdate: false)
			})
		}
	}

	class utils {
		private class func getBytesFromData(field: [String: AnyObject], data: AnyObject?) -> Crypto.Bytes {
			var field_type: String = field["type"] as String
			,	response = Crypto.Bytes()
			let data_class = data == nil ? "" : _stdlib_getDemangledTypeName(data!)
			
			switch field_type {
				case "tinynum":
					if data == nil {
						response.append(0, 0)
					}
					else {
						assert(
							data_class == "__NSCFNumber"
						||	data_class == "Swift.Int"
						, "Invalid type. Expected some integer, '\(data_class)' given.")
						let data_typed: Int = data as Int
						assert(data_typed <= 65535, "Object too large.")
						response.append(UInt8(Int(floor(Double(data_typed/256)))%256), UInt8(data_typed%256))
					}
				case "number":
					if data == nil {
						response = Schemas.getBytesWithLength(Crypto.Bytes(), Schemas.getLengthByType(field_type))
					}
					else {
						assert(
							data_class == "Swift.Int"
						||	data_class == "__NSCFNumber"
						, "Invalid type. Expected some integer, '\(data_class)' given.")
						var data_typed: Int = data as Int

						response = Schemas.getBytesWithLength(Crypto.Bytes(fromNumber: data_typed), Schemas.getLengthByType(field_type))
					}
				case "string":
					var data_bytes = Crypto.Bytes()
					if data != nil {
						assert(
							data_class == "__NSCFString"
						||	data_class == "__NSCFConstantString"
						||	data_class == "Swift.String"
						||	data_class == "Swift._NSContiguousString"
						, "Invalid type. Expected some string, '\(data_class)' given.")
						let data_typed: String = data as String
					
						for scalar in data_typed.unicodeScalars {
							assert(scalar.value < 65536, "Unsupported symbol.")
							if scalar.value < 255 { data_bytes.append(0) }
							data_bytes.append(Crypto.Bytes(fromNumber: Int(scalar.value)))
						}
					}
					response = Schemas.getBytesWithLength(data_bytes, Schemas.getLengthByType(field_type))
				case "bytes":
					if data != nil {
						assert(data_class == "psswd.Crypto.Bytes", "Invalid type. Expected 'psswd.Crypto.Bytes', '\(data_class)' given.")
						response = Schemas.getBytesWithLength(data as Crypto.Bytes, Schemas.getLengthByType(field_type))
					}
					else {
						response = Schemas.getBytesWithLength(Crypto.Bytes(), Schemas.getLengthByType(field_type))
					}
				case "array":
					var data_bytes = Crypto.Bytes()
					if data != nil {
						assert(
							data_class == "Swift.Array"
						||	data_class == "Swift._NSSwiftArrayImpl"
						, "Invalid type. Expected some array, '\(data_class)' given.")
						if let data_typed = data as? [AnyObject] {
							for v in data_typed {
								data_bytes.append(getBytesFromData(field["fields"] as [String: AnyObject], data: v))
							}
						}
					}
					response = Schemas.getBytesWithLength(data_bytes, Schemas.getLengthByType(field_type))
				case "object":
					var data_bytes = Crypto.Bytes()
					if data != nil {
						assert(
							data_class == "__NSDictionaryI"
						||	data_class == "Swift._NativeDictionaryStorageOwner"
						, "Invalid type. Expected some dictionary, '\(data_class)' given.")
					
						if let data_typed = data as? [String: AnyObject] {
							var field_fields = field["fields"] as [[String: AnyObject]]
							for field_in in field_fields {
								let field_in_name = field_in["name"] as String
								data_bytes.append( getBytesFromData(field_in, data: data_typed[field_in_name]) )
							}
						}
					}
					response = Schemas.getBytesWithLength(data_bytes, Schemas.getLengthByType(field_type))
				default:
					assert(false, "Unsupported type '\(field_type)'.")
			}
			return response
		}
		class func dataToSchemaBytes(schema_id: Int, input_data: AnyObject) -> Crypto.Bytes {
			var bytes = Crypto.Bytes()
			var current_schema = classVar.list[schema_id] as [String: AnyObject]

			bytes.append(Int(floor(Double(schema_id / 256))), schema_id % 256)
			
			var data_bytes = getBytesFromData(current_schema, data: input_data)
			data_bytes = data_bytes.slice( Schemas.getLengthByType(current_schema["type"] as String) )
			
			bytes.append(data_bytes)

			return bytes
		}
		
		private class func getDataFromBytes(field: [String: AnyObject], data_bytes: Crypto.Bytes) -> AnyObject {
			var response: AnyObject = 0
			var field_type: String = field["type"] as String
			
			switch field_type {
				case "tinynum", "number":
					response = data_bytes.toNumber()
				case "string":
					response = data_bytes.toSymbols()
				case "bytes":
					response = data_bytes
				case "array":
					var array_bytes = data_bytes
					var array_current_byte = 0
					var array_getBytes = { (field_type: String) -> Crypto.Bytes in
						var bytes_length = 0
						switch field_type {
							case "tinynum":
								bytes_length = 2
							default:
								var n = Schemas.getLengthByType(field_type)
								bytes_length = array_bytes.slice(array_current_byte, length: n).toNumber()
								array_current_byte += n
						}
						var bytes = array_bytes.slice(array_current_byte, length: bytes_length)
						array_current_byte += bytes_length
						return bytes
					}
					var content: [AnyObject] = []
					let field_fields = field["fields"] as [String: AnyObject]
					let field_fields_type = field_fields["type"] as String
					while array_current_byte < array_bytes.count {
						content.append(getDataFromBytes(field_fields, data_bytes: array_getBytes(field_fields_type)))
					}
					response = content
				case "object":
					var object_bytes = data_bytes
					var object_current_byte = 0
					var object_getBytes = { (field_type: String) -> Crypto.Bytes in
						var bytes_length = 0
						switch field_type {
							case "tinynum":
								bytes_length = 2
							default:
								var n = Schemas.getLengthByType(field_type)
								bytes_length = object_bytes.slice(object_current_byte, length: n).toNumber()
								object_current_byte += n
						}
						var bytes = object_bytes.slice(object_current_byte, length: bytes_length)
						object_current_byte += bytes_length
						return bytes
					}
					var content: [String: AnyObject] = [:]
					let field_fields = field["fields"] as [[String: AnyObject]]
					for field_in in field_fields {
						content[field_in["name"] as String] = getDataFromBytes(field_in, data_bytes: object_getBytes(field_in["type"] as String))
					}
					response = content
				default:
					assert(false, "Unsupported type '\(field_type)'.")
			}
			
			return response
		}
		
		class func schemaBytesToData(schema_bytes: Crypto.Bytes) -> AnyObject {
			assert(schema_bytes.count > 2, "Invalid bytes passed.")

			let schema_id = schema_bytes.slice(0, length: 2).toNumber()
			
			let field = classVar.list[schema_id] as [String: AnyObject]
			
			var output_data: AnyObject = getDataFromBytes(field, data_bytes: schema_bytes.slice(2))
			
			return output_data
		}
	}
	
	private class func getLengthByType(type: String) -> Int {
			var length = 2
			switch(type){
			case "tinynum": length = 0
			case "number": length = 1
			case "array", "object": length = 4
			default: break
			}
			return length
	}
	private class func getBytesWithLength(bytes: Crypto.Bytes, _ bytes_for_length: Int = 2) -> Crypto.Bytes {
		if bytes_for_length == 0 {
			return bytes
		}
		
		var length = bytes.count
		assert(Int64(length) <= Int64(pow(Double(256), Double(bytes_for_length))), "Schemas.getBytesWithLength(): Object too large.")
		
		var res = Crypto.Bytes(fromNumber: length)
		//println( res.asArray() )
		while bytes_for_length != res.count { res = Crypto.Bytes(given: [0]).concat(res) }
		//println( res.asArray() )
		res.append(bytes)
		//println( res.asArray() )
		return res
	}
}
