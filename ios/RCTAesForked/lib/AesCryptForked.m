//
//  AesCryptForked.m
//
//  Created by tectiv3 on 10/02/17. Forked by Metamask in 2018. 
//  Forked by Artzlabs in 2022
//  Copyright © 2017 tectiv3. All rights reserved.
//

#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonKeyDerivation.h>

#import "AesCryptForked.h"

@implementation AesCryptForked

+ (NSString *) toHex:(NSData *)nsdata {
    NSMutableData *result = [NSMutableData dataWithLength:2*nsdata.length];
        unsigned const char* src = nsdata.bytes;
        unsigned char* dst = result.mutableBytes;
        unsigned char t0, t1;

        for (int i = 0; i < nsdata.length; i ++ ) {
             t0 = src[i] >> 4;
             t1 = src[i] & 0x0F;

             dst[i*2] = 48 + t0 + (t0 / 10) * 39;
             dst[i*2+1] = 48 + t1 + (t1 / 10) * 39;
        }

        return [[NSString alloc] initWithData:result encoding:NSASCIIStringEncoding];
}

+ (NSData *) fromHex: (NSString *)string {
    NSMutableData *data = [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < ([string length] / 2); i++) {
        byte_chars[0] = [string characterAtIndex:i*2];
        byte_chars[1] = [string characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}

+ (NSString *) pbkdf2:(NSString *)password salt: (NSString *)salt {
    // Data of String to generate Hash key(hexa decimal string).
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSData *saltData = [salt dataUsingEncoding:NSUTF8StringEncoding];

    // Hash key (hexa decimal) string data length.
    NSMutableData *hashKeyData = [NSMutableData dataWithLength:32];

    // Key Derivation using PBKDF2 algorithm.
    int status = CCKeyDerivationPBKDF(
                    kCCPBKDF2,
                    passwordData.bytes,
                    passwordData.length,
                    saltData.bytes,
                    saltData.length,
                    kCCPRFHmacAlgSHA512,
                    5000,
                    hashKeyData.mutableBytes,
                    hashKeyData.length);

    if (status == kCCParamError) {
        NSLog(@"Key derivation error");
        return @"";
    }

    return [self toHex:hashKeyData];
}

+ (NSData *) AES128CBC: (NSString *)operation data: (NSData *)data key: (NSString *)key iv: (NSString *)iv {
    //convert hex string to hex data
    NSData *keyData = [self fromHex:key];
    NSData *ivData = [self fromHex:iv];
    //    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    size_t numBytes = 0;

    NSMutableData * buffer = [[NSMutableData alloc] initWithLength:[data length] + kCCBlockSizeAES128];

    CCCryptorStatus cryptStatus = CCCrypt(
                                          [operation isEqualToString:@"encrypt"] ? kCCEncrypt : kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          keyData.bytes, keyData.length,
                                          ivData.bytes,
                                          data.bytes, data.length,
                                          buffer.mutableBytes,  buffer.length,
                                          &numBytes);

    if (cryptStatus == kCCSuccess) {
        [buffer setLength:numBytes];
        return buffer;
    }
    NSLog(@"AES error, %d", cryptStatus);
    return nil;
}

+ (NSString *) encrypt: (NSString *)clearText key: (NSString *)key iv: (NSString *)iv {
    NSData *result = [self AES128CBC:@"encrypt" data:[clearText dataUsingEncoding:NSUTF8StringEncoding] key:key iv:iv];
    return [result base64EncodedStringWithOptions:0];
}

+ (NSString *) decrypt: (NSString *)cipherText key: (NSString *)key iv: (NSString *)iv {
    NSData *result = [self AES128CBC:@"decrypt" data:[[NSData alloc] initWithBase64EncodedString:cipherText options:0] key:key iv:iv];
    return [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
}

+ (NSString *) hmac256: (NSString *)input key: (NSString *)key {
    NSData *keyData = [self fromHex:key];
    NSData* inputData = [input dataUsingEncoding:NSUTF8StringEncoding];
    void* buffer = malloc(CC_SHA256_DIGEST_LENGTH);
    CCHmac(kCCHmacAlgSHA256, [keyData bytes], [keyData length], [inputData bytes], [inputData length], buffer);
    NSData *nsdata = [NSData dataWithBytesNoCopy:buffer length:CC_SHA256_DIGEST_LENGTH freeWhenDone:YES];
    return [self toHex:nsdata];
}

+ (NSString *) hmac512: (NSString *)input key: (NSString *)key {
    NSData *keyData = [self fromHex:key];
    NSData* inputData = [input dataUsingEncoding:NSUTF8StringEncoding];
    void* buffer = malloc(CC_SHA512_DIGEST_LENGTH);
    CCHmac(kCCHmacAlgSHA512, [keyData bytes], [keyData length], [inputData bytes], [inputData length], buffer);
    NSData *nsdata = [NSData dataWithBytesNoCopy:buffer length:CC_SHA512_DIGEST_LENGTH freeWhenDone:YES];
    return [self toHex:nsdata];
}

+ (NSString *) sha1: (NSString *)input {
    NSData* inputData = [input dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *result = [[NSMutableData alloc] initWithLength:CC_SHA1_DIGEST_LENGTH];
    CC_SHA1([inputData bytes], (CC_LONG)[inputData length], result.mutableBytes);
    return [self toHex:result];
}

+ (NSString *) sha256: (NSString *)input {
    NSData* inputData = [input dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char* buffer = malloc(CC_SHA256_DIGEST_LENGTH);
    CC_SHA256([inputData bytes], (CC_LONG)[inputData length], buffer);
    NSData *result = [NSData dataWithBytesNoCopy:buffer length:CC_SHA256_DIGEST_LENGTH freeWhenDone:YES];
    return [self toHex:result];
}

+ (NSString *) sha512: (NSString *)input {
    NSData* inputData = [input dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char* buffer = malloc(CC_SHA512_DIGEST_LENGTH);
    CC_SHA512([inputData bytes], (CC_LONG)[inputData length], buffer);
    NSData *result = [NSData dataWithBytesNoCopy:buffer length:CC_SHA512_DIGEST_LENGTH freeWhenDone:YES];
    return [self toHex:result];
}

+ (NSString *) randomUuid {
  return [[NSUUID UUID] UUIDString];
}

+ (NSString *) randomKey: (NSInteger)length {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    int result = SecRandomCopyBytes(kSecRandomDefault, length, data.mutableBytes);
    if (result != noErr) {
        return nil;
    }
    return [self toHex:data];
}


@end
