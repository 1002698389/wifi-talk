//
//  TCPCommand.h
//  WifiTalk
//
//  Created by Joey Patino on 7/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


/*
    TCPCommand: This class encapsulates a TCPCommand that is sent over a 
    TCP Connection. Please note that to ensure proper delivery of the Command,
    The sending and recieving devices must append the proper sized header 
    (sizeOfHeaderPacket). This header must be a padded string representation 
    of the length of the actual payload (eg. 00000284 for a 284 byte length 
    payload). This logic is contained within TCPCommand.
*/

#define kCommandNameKey @"COMMAND"
#define kParametersKey  @"PARAMETERS"
#define sizeOfHeaderPacket 8

@interface TCPCommand : NSObject

@property (nonatomic, strong) NSString *commandName;
@property (nonatomic, strong) id parameter;

// create a TCPCommand with payloadBytes. This method is useful 
// for constructing a recieved TCPCommand with data ready from a 
// TCPConnection input stream
- (id)initWithPayloadBytes:(char *)payloadBytes;

// This method returns the entire TCP command including header
// and payload. This is what you send over the network to other clients
- (NSString *)tcpCommandString;

@end
