//
//  TCPCommand.m
//  WifiTalk
//
//  Created by Joey Patino on 7/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TCPCommand.h"

@interface TCPCommand()

- (NSDictionary *)jsonPayload;
@end


@implementation TCPCommand
@synthesize commandName;
@synthesize parameter;



- (id)initWithPayloadBytes:(char *)payloadBytes {

    self = [super init];

    NSString *payloadString = [NSString stringWithCString:payloadBytes encoding:NSUTF8StringEncoding];

    NSDictionary *payload = [payloadString JSONValue];
    
    self.commandName = [payload objectForKey:kCommandNameKey];
    self.parameter = [payload objectForKey:kParametersKey];
    
    return self;
}

- (NSString *)description {

    return [NSString stringWithFormat:@"<%@ | Command: \"%@\" | ParameterType: \"%@\">", [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self], self.commandName, NSStringFromClass([self.parameter class])];
}

// create the payload dictionary.
- (NSDictionary *)jsonPayload {

    NSDictionary* payload = [NSDictionary dictionaryWithObjectsAndKeys:self.commandName, kCommandNameKey, self.parameter, kParametersKey, nil];

    return payload;
}

// create the header for our command. 
- (NSString *)tcpHeader {

    // create a buffer that will hold the header first.
    char *header = malloc(sizeOfHeaderPacket);

    // clear it out so that we start off clean.
    memset(header, '\0', sizeOfHeaderPacket);

    // get the payload string representation..
    NSString *cmdString = [[self jsonPayload] JSONRepresentation];
    
//    NSLog(@"DD cmdString %@", cmdString);
//    NSLog(@"DD [cmdString length] %i", [cmdString length]);

    // now create the header based on the length of the payload..
    NSString *headerString = [NSString stringWithFormat:@"%i", [cmdString length]];
    headerString = [headerString stringPaddedWithCharacter:"0" toLength:sizeOfHeaderPacket];
    
    return headerString;
}

// this will create and return the entire tcp command 
// and return it as an nsstring. this includes the header and payload
- (NSString *)tcpCommandString {
    
    NSString *headerString = [self tcpHeader];
    NSString *payloadString = [[self jsonPayload] JSONRepresentation];
    NSString *tcpCommandString = nil;

    tcpCommandString = [NSString stringWithFormat:@"%@%@", headerString, payloadString];

//    NSLog(@"headerString %@", headerString);
//
//    NSLog(@"payloadString %@", payloadString);
//
//    NSLog(@"tcpCommandString %@", tcpCommandString);

    return tcpCommandString;
}

@end
