//
//  ObjC_Crypto.m
//  psswd
//
//  Created by Daniil on 20.12.14.
//  Copyright (c) 2014 kirick. All rights reserved.
//

#import "ObjC_Crypto.h"

@implementation ObjC_Crypto

+ (NSData*) pbkdf2:(NSData*)password
			  hash:(NSData*)hash
		iterations:(int)iterations
{
	//NSString* _password = [[NSString alloc] initWithData:password encoding:NSUTF8StringEncoding];
	NSMutableData* key = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
	CCKeyDerivationPBKDF(kCCPBKDF2, password.bytes, password.length, hash.bytes, hash.length, kCCPRFHmacAlgSHA1, iterations, key.mutableBytes, key.length);
	return key;
}

+ (NSData*) aesEncrypt:(NSData*)data
				   key:(NSData*)key
					iv:(NSData*)iv
{
	//NSLog(@"Key : %@", [key base64EncodedStringWithOptions:0]);
	//NSLog(@"Key length : %d", key.length);
	
	//NSLog(@"IV : %@", [iv base64EncodedStringWithOptions:0]);
	
	// Encrypt message into base64
	NSData* message = data;
	NSMutableData* encrypted = [NSMutableData dataWithLength:message.length + kCCBlockSizeAES128];
	size_t bytesEncrypted = 0;
	CCCrypt(kCCEncrypt,
			kCCAlgorithmAES128,
			kCCOptionPKCS7Padding,
			key.bytes,
			key.length,
			iv.bytes,
			message.bytes, message.length,
			encrypted.mutableBytes, encrypted.length, &bytesEncrypted);
	NSData* data_encrypted = [NSMutableData dataWithBytes:encrypted.mutableBytes length:bytesEncrypted];
	//NSString* encrypted64 = [data_encrypted base64EncodedStringWithOptions:0];
	//NSLog(@"Encrypted : %@", encrypted64);
	
	return data_encrypted;
}
+ (NSData*) aesDecrypt:(NSData*)data
				   key:(NSData*)key
					iv:(NSData*)iv
{
	//NSLog(@"Key : %@", [key base64EncodedStringWithOptions:0]);
	//NSLog(@"Key length : %d", key.length);
	
	//NSLog(@"IV : %@", [iv base64EncodedStringWithOptions:0]);

	// Decrypt base 64 into message again
	NSMutableData* decrypted = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];
	size_t bytesDecrypted = 0;
	CCCrypt(kCCDecrypt,
			kCCAlgorithmAES128,
			kCCOptionPKCS7Padding,
			key.bytes,
			key.length,
			iv.bytes,
			data.bytes, data.length,
			decrypted.mutableBytes, decrypted.length, &bytesDecrypted);
	NSData* outputMessage = [NSMutableData dataWithBytes:decrypted.mutableBytes length:bytesDecrypted];
	//NSString* output64 = [outputMessage base64EncodedStringWithOptions:0];
	//NSLog(@"Decrypted : %@", output64);
	
	return outputMessage;
}

SecKeyRef publicKey;
SecCertificateRef certificate;
SecPolicyRef policy;
SecTrustRef trust;
size_t maxPlainLen = -1;

+(void) rsaCreateKey
{
	NSString *publicKeyPath = [[NSBundle mainBundle] pathForResource:@"public_key" ofType:@"der"];
	if (publicKeyPath == nil) {
		NSLog(@"Can not find .der");
		return;
	}
	
	NSData *publicKeyFileContent = [NSData dataWithContentsOfFile: publicKeyPath];
	if (publicKeyFileContent == nil) {
		NSLog(@"Can not read from .der");
		return;
	}
	
	certificate = SecCertificateCreateWithData(kCFAllocatorDefault, ( __bridge CFDataRef)publicKeyFileContent);
	if (certificate == nil) {
		NSLog(@"Can not read certificate from .der");
		return;
	}
	
	policy = SecPolicyCreateBasicX509();
	OSStatus returnCode = SecTrustCreateWithCertificates(certificate, policy, &trust);
	if (returnCode != 0) {
		NSLog(@"SecTrustCreateWithCertificates fail. Error Code: %ld", (long int)returnCode);
		return;
	}
	
	SecTrustResultType trustResultType;
	returnCode = SecTrustEvaluate(trust, &trustResultType);
	if (returnCode != 0) {
		return;
	}
	
	publicKey = SecTrustCopyPublicKey(trust);
	if (publicKey == nil) {
		NSLog(@"SecTrustCopyPublicKey fail");
		return;
	}
	
	maxPlainLen = SecKeyGetBlockSize(publicKey) - 12;
}

+ (NSData*) rsaEncrypt:(NSData*)data
{
	if (-1 == maxPlainLen) { [self rsaCreateKey]; }
	
	size_t plainLen = [data length];
	if (plainLen > maxPlainLen) {
		NSLog(@"content(%ld) is too long, must < %ld", plainLen, maxPlainLen);
		return nil;
	}
	
	void *plain = malloc(plainLen);
	[data getBytes:plain length:plainLen];
	
	size_t cipherLen = 2048 / 8; // key length in bytes
	void *cipher = malloc(cipherLen);
	
	OSStatus returnCode = SecKeyEncrypt(publicKey, kSecPaddingPKCS1, plain, plainLen, cipher, &cipherLen);
	
	NSData *result = nil;
	if (returnCode != 0) {
		NSLog(@"SecKeyEncrypt fail. Error Code: %ld", (long int)returnCode);
	}
	else {
		result = [NSData dataWithBytes:cipher length:cipherLen];
	}
	
	free(plain);
	free(cipher);
	
	return result;
}

@end
