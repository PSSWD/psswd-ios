//
//  ObjC_Crypto.h
//  psswd
//
//  Created by Daniil on 12.01.15.
//  Copyright (c) 2015 kirick. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>

@interface ObjC_Crypto : NSObject 

+ (NSData*) pbkdf2:(NSData*)password
			  hash:(NSData*)hash
		iterations:(int)iterations;

+ (NSData*) aesEncrypt:(NSData*)data
				   key:(NSData*)key
					iv:(NSData*)iv;
+ (NSData*) aesDecrypt:(NSData*)data
				   key:(NSData*)key
					iv:(NSData*)iv;

+ (NSData*) rsaEncrypt:(NSData*)data;

@end