//
//  ObjC_Crypto.m
//  psswd
//
//  Created by Daniil on 20.12.14.
//  Copyright (c) 2014 kirick. All rights reserved.
//

#import "ObjC_Crypto.h"

@implementation ObjC_Crypto

+ (NSData*) sha256:(NSData *)data
{
	uint8_t digest[CC_SHA256_DIGEST_LENGTH] = {0};
	CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
	NSData *result=[NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
	return result;
}

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
	size_t outLength;
	NSMutableData *cipherData = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];
	
	CCCryptorStatus result = CCCrypt(kCCEncrypt,
									 kCCAlgorithmAES128,
									 kCCOptionPKCS7Padding,
									 key.bytes, // key
									 key.length, // keylength
									 iv.bytes,// iv
									 data.bytes, // dataIn
									 data.length, // dataInLength,
									 cipherData.mutableBytes, // dataOut
									 cipherData.length, // dataOutAvailable
									 &outLength); // dataOutMoved
	
	if (result == kCCSuccess) {
		cipherData.length = outLength;
	}
	else {
		NSLog(@"ERROR");
		return nil;
	}
	
	return cipherData;
}
+ (NSData*) aesDecrypt:(NSData*)data
				   key:(NSData*)key
					iv:(NSData*)iv
{
	size_t outLength;
	NSMutableData *cipherData = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];
	
	CCCryptorStatus result = CCCrypt(kCCDecrypt,
									 kCCAlgorithmAES128,
									 kCCOptionPKCS7Padding,
									 key.bytes, // key
									 key.length, // keylength
									 iv.bytes,// iv
									 data.bytes, // dataIn
									 data.length, // dataInLength,
									 cipherData.mutableBytes, // dataOut
									 cipherData.length, // dataOutAvailable
									 &outLength); // dataOutMoved
	
	if (result == kCCSuccess) {
		cipherData.length = outLength;
	}
	else {
		NSLog(@"ERROR");
		return nil;
	}
	
	return cipherData;
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
