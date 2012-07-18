//
//  CommandBuilder.m
//  WifiTalk
//
//  Created by Joey Patino on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CommandBuilder.h"
#import "TCPCommand.h"

@implementation CommandBuilder

+ (id)CommandWithName:(NSString *)commandName parameterValue:(id)value {
    TCPCommand *command = [[TCPCommand alloc] init];
    
    command.commandName = commandName;

    if (value != nil)
        command.parameter = value;

    return command;
}

@end
