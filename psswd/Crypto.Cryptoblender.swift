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
			return Cryptoblender4.encrypt(data, withKey: key)
		}
		class func decrypt(data: Crypto.Bytes, withKey key: Crypto.Bytes) -> Crypto.Bytes
		{
			switch data.getByteAt(0)
			{
			case 4:
				return Cryptoblender4.decrypt(data, withKey: key)
			default:
				assert(false, "Unknown version of cryptoblender used.")
			}
		}
	}
	
	class Cryptoblender4
	{
		class func encrypt(data: Crypto.Bytes, withKey key: Crypto.Bytes) -> Crypto.Bytes
		{
			var bytes = Crypto.Bytes(given: [0x4])
			,	randLength = Int( MTRandom().randomUInt32From(8, to: 16) )
			,	salt = Crypto.Bytes(given: [206, 192, 255, 190, 74, 177, 104, 180, 130, 203, 165, 226, 135, 246, 35, 127, 44, 227, 45, 48, 158, 112, 180, 115, 111, 107, 44, 3, 33, 141, 249, 251])
			,	data = Crypto.Bytes().append(randLength)
				.append( Crypto.Bytes(randomWithLength: randLength) )
				.append(data)
			,	data_hash = data.getSHA1()
			
			let aes_key = Crypto.PBKDF2(key, hash: data_hash, iterations: 5_000)
			let aes_iv = Crypto.PBKDF2(data_hash, hash: salt, iterations: 1)
			
			let data_encrypted = Crypto.AES.encrypt(data, key: aes_key, iv: aes_iv)
			
			bytes.append(data_hash).append(data_encrypted)
			
			return bytes
		}
		class func decrypt(data: Crypto.Bytes, withKey key: Crypto.Bytes) -> Crypto.Bytes
		{
			var data_hash = data.slice(1, length: 20)
			,	enc = data.slice(21)
			,	salt = Crypto.Bytes(given: [206, 192, 255, 190, 74, 177, 104, 180, 130, 203, 165, 226, 135, 246, 35, 127, 44, 227, 45, 48, 158, 112, 180, 115, 111, 107, 44, 3, 33, 141, 249, 251])
			
			let aes_key = Crypto.PBKDF2(key, hash: data_hash, iterations: 5_000)
			let aes_iv = Crypto.PBKDF2(data_hash, hash: salt, iterations: 1)
			
			let dec = Crypto.AES.decrypt(enc, key: aes_key, iv: aes_iv)
			
			assert(dec.getSHA1().toHex() == data_hash.toHex(), "Crypto.Cryptoblender: Invalid data or key.")
			
			return dec.slice(1 + Int( dec.getByteAt(0) ))
		}
	}
}
