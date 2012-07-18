//
//  NSString+Hex.m
//  WifiTalk
//
//  Created by Joey Patino on 7/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+Hex.h"

const static char hexchar[] = "0123456789ABCDEF";
@implementation NSString (Hex)

+ (NSData *)dataFromHexString:(NSString *)hexString {
    
    NSMutableData *dataFromHex= [[NSMutableData alloc] init];
    
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    
    for (int i = 0; i < ([hexString length]/2); i++) {
        
        byte_chars[0] = [hexString characterAtIndex:i*2];
        byte_chars[1] = [hexString characterAtIndex:(i*2)+1];
        
        whole_byte = strtol(byte_chars, NULL, 16);
        [dataFromHex appendBytes:&whole_byte length:1];
    }
    
    return dataFromHex;
}


+ (NSString*) stringFromHexData:(NSData *)data {
    
    const char *buffer = [data bytes];
    int buf_len = [data length];
    
    size_t i;
    char *p;
    int len = (buf_len * 2) + 1;
    p = malloc(len);
    for (i = 0; i < buf_len; i++) {
        p[i * 2] = hexchar[(unsigned char)buffer[i] >> 4 & 0xf];
        p[i * 2 + 1] = hexchar[((unsigned char)buffer[i] ) & 0xf];
    }
    p[i * 2] = '\0';
    NSString * result = [NSString stringWithCString:p encoding:NSUTF8StringEncoding];
    free(p); 
    return result; 
}

@end
