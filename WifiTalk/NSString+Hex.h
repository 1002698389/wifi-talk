//
//  NSString+Hex.h
//  WifiTalk
//
//  Created by Joey Patino on 7/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Hex)

+ (NSData *)dataFromHexString:(NSString *)hexString;
+ (NSString*)stringFromHexData:(NSData *)data;

@end
