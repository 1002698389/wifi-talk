//
//  CommandBuilder.h
//  WifiTalk
//
//  Created by Joey Patino on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

/*
    Factory class to create TCPCommands. Very simple.
*/

@class TCPCommand;
@interface CommandBuilder : NSObject

+ (id)CommandWithName:(NSString *)commandName parameterValue:(id)value;

@end
