//
//  KDCrypto.swift
//  psswd
//
//  Created by daniil on 03.08.14.
//  Copyright (c) 2014 daniil. All rights reserved.
//

import UIKit

class Crypto {
	class func SHA1(string: String) -> Crypto.Bytes
	{
		let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
		return SHA1(data)
	}
	class func SHA1(data: NSData) -> Crypto.Bytes
	{
		var digest = [UInt8](count:Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
		CC_SHA1(data.bytes, CC_LONG(data.length), &digest)
		return Crypto.Bytes(given: digest)
	}
	class func SHA256(string: String) -> Crypto.Bytes
	{
		let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
		return SHA256(data)
	}
	class func SHA256(data: NSData) -> Crypto.Bytes
	{
		//var digest = [UInt8](count:Int(CC_SHA256_DIGEST_LENGTH), repeatedValue: 0)
		//CC_SHA256(data.bytes, CC_LONG(data.length), &digest)
		return Crypto.Bytes(fromNSData: ObjC_Crypto.sha256(data))
	}

	class func PBKDF2(key: Crypto.Bytes, hash: Crypto.Bytes, iterations: Int) -> Crypto.Bytes
	{
		return Crypto.Bytes(fromNSData: ObjC_Crypto.pbkdf2(key.toNSData(), hash: hash.toNSData(), iterations: Int32(iterations)))
	}

	class AES
	{
		class func encrypt(data: Crypto.Bytes, key: Crypto.Bytes, iv: Crypto.Bytes) -> Crypto.Bytes
		{
			return Crypto.Bytes(fromNSData: ObjC_Crypto.aesEncrypt(
				data.toNSData(),
				key: key.toNSData(),
				iv: iv.toNSData()
				)
			)
		}
		class func decrypt(data: Crypto.Bytes, key: Crypto.Bytes, iv: Crypto.Bytes) -> Crypto.Bytes
		{
			return Crypto.Bytes(fromNSData: ObjC_Crypto.aesDecrypt(
				data.toNSData(),
				key: key.toNSData(),
				iv: iv.toNSData()
				)
			)
		}
	}
	
	class RSA
	{
		class func encrypt(bytes: Crypto.Bytes) -> Crypto.Bytes
		{
			return Crypto.Bytes(fromNSData: ObjC_Crypto.rsaEncrypt( bytes.toNSData() ))
		}
	}
}