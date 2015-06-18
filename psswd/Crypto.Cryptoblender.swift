//
//  Crypto.Cryptoblender.swift
//  psswd
//
//  Created by Daniil on 19.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

extension Crypto
{
	class Cryptoblender
	{
		class func encrypt(data: Crypto.Bytes, withKey key: Crypto.Bytes) -> Crypto.Bytes
		{
			return Cryptoblender6.encrypt(data, withKey: key)
		}
		class func decrypt(data: Crypto.Bytes, withKey key: Crypto.Bytes) -> Crypto.Bytes
		{
			switch data.getByteAt(0)
			{
			case 6:
				return Cryptoblender6.decrypt(data, withKey: key)
			default:
				assert(false, "Unknown version of cryptoblender used.")
			}
		}
	}
	
	class Cryptoblender6
	{
		private static let aes_key_salts = [
			Crypto.Bytes(given: [110, 125, 22, 20, 133, 39, 248, 120, 45, 131, 140, 198, 154, 126, 42, 194]),
			Crypto.Bytes(given: [96, 22, 43, 45, 106, 222, 10, 233, 50, 216, 1, 254, 120, 189, 142, 15]),
			Crypto.Bytes(given: [2, 160, 195, 202, 161, 65, 77, 250, 32, 54, 208, 90, 170, 47, 219, 231]),
			Crypto.Bytes(given: [119, 174, 224, 98, 1, 203, 71, 27, 0, 236, 192, 88, 70, 122, 39, 250]),
			Crypto.Bytes(given: [240, 240, 246, 225, 177, 34, 171, 194, 116, 86, 35, 101, 240, 159, 7, 197]),
			Crypto.Bytes(given: [54, 232, 38, 103, 144, 169, 77, 125, 73, 189, 108, 101, 28, 39, 234, 93]),
			Crypto.Bytes(given: [89, 139, 49, 37, 67, 200, 61, 56, 221, 27, 160, 172, 120, 180, 177, 101]),
			Crypto.Bytes(given: [74, 105, 126, 5, 16, 157, 183, 233, 88, 212, 42, 101, 198, 102, 165, 61])
		]
		class func encrypt(data: Crypto.Bytes, withKey key: Crypto.Bytes) -> Crypto.Bytes
		{
			var bytes = Crypto.Bytes(given: [0x6])
			,	randLength = Int( MTRandom().randomUInt32From(8, to: 16) )
			,	salt = Crypto.Bytes(given: [206, 192, 255, 190, 74, 177, 104, 180, 130, 203, 165, 226, 135, 246, 35, 127, 44, 227, 45, 48, 158, 112, 180, 115, 111, 107, 44, 3, 33, 141, 249, 251])
			,	data = Crypto.Bytes().append(randLength)
				.append( Crypto.Bytes(randomWithLength: randLength) )
				.append(data)
			,	data_hash = data.getSHA256()
			
			var aes_key = key
			for i in aes_key_salts {
				aes_key = aes_key.concat(i).concat(data_hash).getSHA256()
			}
			let aes_iv = Crypto.PBKDF2(data_hash, hash: salt, iterations: 1)
			
			let data_encrypted = Crypto.AES.encrypt(data, key: aes_key, iv: aes_iv)
			
			bytes.append(data_hash).append(data_encrypted)
			
			return bytes
		}
		class func decrypt(data: Crypto.Bytes, withKey key: Crypto.Bytes) -> Crypto.Bytes
		{
			var data_hash = data.slice(1, length: 32)
			,	enc = data.slice(33)
			,	salt = Crypto.Bytes(given: [206, 192, 255, 190, 74, 177, 104, 180, 130, 203, 165, 226, 135, 246, 35, 127, 44, 227, 45, 48, 158, 112, 180, 115, 111, 107, 44, 3, 33, 141, 249, 251])
			
			var aes_key = key
			for i in aes_key_salts {
				aes_key = aes_key.concat(i).concat(data_hash).getSHA256()
			}
			let aes_iv = Crypto.PBKDF2(data_hash, hash: salt, iterations: 1)
			
			let dec = Crypto.AES.decrypt(enc, key: aes_key, iv: aes_iv)
			
			assert(dec.getSHA256().toHex() == data_hash.toHex(), "Crypto.Cryptoblender: Invalid data or key.")
			
			return dec.slice(1 + Int( dec.getByteAt(0) ))
		}
	}
}
