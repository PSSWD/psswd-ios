//
//  Crypto.Bytes.swift
//  psswd
//
//  Created by Daniil on 19.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

extension Crypto
{
	class Bytes: NSObject, Printable
	{
		private var data: [UInt8]
		override var description: String
		{
			var res = ""
			for c in data { res += (count(res) == 0 ? "" : ", ") + "\(c)" }
			return "Crypto.Bytes( " + res + (count(res) == 0 ? "" : " ") + ")"
		}
		override init()
		{
			data = []
		}
		init(given: [UInt8])
		{
			data = given
		}
		init(base64String: String)
		{
			var decodedData: NSData = NSData(base64EncodedString: base64String, options: NSDataBase64DecodingOptions(0))!
			data = Bytes(fromNSData: decodedData).asArray()
		}
		init(fromNSData nsdata: NSData)
		{
			data = []
			var count = nsdata.length / sizeof(UInt8)
			var array = [UInt8](count: count, repeatedValue: 0)
			
			nsdata.getBytes(&array, length:count * sizeof(UInt8))
			for i in array {
				data.append( UInt8(i) )
			}
		}
		init(fromString string: String)
		{
			data = []
			for scalar in string.unicodeScalars {
				assert(scalar.value < 65536, "Unsupported symbol.")
				if scalar.value < 255 { data.append(0) }
				data.append( UInt8(scalar.value) )
			}
		}
		init(fromNumber number: Int)
		{
			data = Crypto.Bytes(fromHexString: NSString(format:"%2X", number) as String).asArray()
		}
		init(fromHexString _hex: String)
		{
			var hex = _hex
			if count(hex) % 2 == 1 { hex = "0" + hex }
			var syms = Array(hex)
			var res: [UInt8] = []
			for var i = 0; i < syms.count; i += 2 {
				var num = (String(syms[i]) + String(syms[i + 1])).withCString { strtoul($0, nil, 16) }
				res.append( UInt8(num) )
			}
			data = res
			count(hex)
		}
		init(randomWithLength length: Int)
		{
			data = []
			for i in 0 ..< length {
				data.append( UInt8( MTRandom().randomUInt32From(0, to: 255) ) )
			}
		}
		var length: Int { return data.count }
		func asArray() -> [UInt8] {
			return data
		}
		func append(byte: UInt8...) -> Crypto.Bytes {
			data += byte
			return self
		}
		func append(byte: Int...) -> Crypto.Bytes {
			for i in byte { data.append( UInt8(i) ) }
			return self
		}
		func append(bytes: Crypto.Bytes) -> Crypto.Bytes {
			data += bytes.asArray()
			return self
		}
		func concat(bytes: Crypto.Bytes) -> Crypto.Bytes {
			return Crypto.Bytes(given: data + bytes.asArray())
		}
		func getByteAt(pos: Int) -> UInt8 {
			return data[pos]
		}
		func slice(start: Int, length: Int? = nil) -> Crypto.Bytes {
			var sliced: [UInt8] = []
			if data.count == 0 { return Crypto.Bytes() }
			var end = data.count - 1
			if length != nil { end = min(end, start + length! - 1) }
			if start <= end {
				sliced = Array(data[start...end])
			}
			return Crypto.Bytes(given: sliced)
		}
		func print(separator: String = ",") -> String {
			var res: String = ""
			for i in 0 ..< data.count {
				res += (i > 0 ? separator : "") + "\(data[i])"
			}
			return res
		}
		func getSHA1() -> Bytes {
			return Crypto.SHA1( self.toNSData() )
		}
		func getSHA256() -> Bytes {
			return Crypto.SHA256( self.toNSData() )
		}
		func toHex() -> String {
			var g = ""
			for num in data {
				g += NSString(format:"%02x", num) as String
			}
			return g
		}
		func toNSData() -> NSData {
			var bts = [UInt8]()
			for i in data { bts.append(i) }
			return NSData(bytes: &bts, length: data.count)
		}
		func toSymbols(oneByte: Bool = false) -> String {
			var g = ""
			if oneByte {
				for _byte in data {
					g += String( UnicodeScalar(_byte) )
				}
			} else {
				if data.count % 2 == 1 {
					NSException(name: "Wrong bytes", reason: "Count of bytes must be even.", userInfo: nil)
				}
				for var i = 0; i < data.count; i += 2 {
					g += String(UnicodeScalar(Int(data[i]) * 256 + Int(data[i + 1])))
				}
			}
			return g
		}
		func toNumber() -> Int {
			var res = 0
			for i in 0 ..< data.count {
				res += Int(data[i]) * Int(pow(Double(256), Double(data.count - i - 1)))
			}
			return res
		}
	}
}
