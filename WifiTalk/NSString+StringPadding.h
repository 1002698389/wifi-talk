//
//  NSString+StringPadding.h
//  WifiTalk
//
//  Created by Joey Patino on 7/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (StringPadding)
- (NSString *)stringPaddedWithCharacter:(char *)character toLength:(int)length;

@end
