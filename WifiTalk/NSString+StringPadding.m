//
//  NSString+StringPadding.m
//  WifiTalk
//
//  Created by Joey Patino on 7/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+StringPadding.h"

@implementation NSString (StringPadding)
- (NSString *)stringPaddedWithCharacter:(char *)character toLength:(int)length {
    
    NSString *result = self;
    for (int i = [result length]; i < length; i++){
        result = [NSString stringWithFormat:@"%s%@", character, result];
    }
    
    return result;
}
@end
