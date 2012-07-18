//
//  TCPConnection.m
//  WifiTalk
//
//  Created by Joey Patino on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TCPConnection.h"
#import "TCPCommand.h"


@interface TCPConnection () <NSStreamDelegate> {

    int currentByteOffset;
    int totalBytesInPayload;
}

- (void)closeStreams;
- (void)openStreams;
@end



@implementation TCPConnection
@synthesize delegate;

@synthesize inputStream;
@synthesize outputStream;
@synthesize inReady;
@synthesize outReady;
@synthesize currentConnectionData;

- (id)init {
    self = [super init];
    
    self.currentConnectionData = [NSMutableData data];
    
    return self;
}

- (void)sendCommand:(TCPCommand *)cmd {
    
	if (self.outputStream && [self.outputStream hasSpaceAvailable]) {
        
        // grab the entire TCPCommand that we will be sending over the output stream
        NSString *tcpCommandAsString = [cmd tcpCommandString];

//        NSLog(@"tcpCommandAsString %@", tcpCommandAsString);
        
        // get the size and create a buffer to hold the byte array
        int sizeOfTCPCommand = [tcpCommandAsString length];
//        NSLog(@"sizeOfTCPCommand %i", sizeOfTCPCommand);

        uint8_t *command[sizeOfTCPCommand];

        // nil our the buffer to keep things clean, then copy the entire TCPCommand to the buffer.
        memset(command, 0, sizeOfTCPCommand);
        memcpy(command, [tcpCommandAsString UTF8String], sizeOfTCPCommand);
        
        // finally write the command to the output stream. when finished, notify the delegate.
        if([self.outputStream write:(const uint8_t *)command maxLength:sizeOfTCPCommand] == -1) {
            
        }
        else {
            [self.delegate tcpConnection:self didSendCommand:cmd];
        }
    }
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    
	switch(eventCode) {
		case NSStreamEventOpenCompleted: {

			if (stream == self.inputStream)
				self.inReady = YES;
			else
				self.outReady = YES;
            
            if (self.inReady && self.outReady) {
                [self.delegate tcpConnectionDidOpen:self];
            }
            
            break;
		}
		case NSStreamEventHasBytesAvailable: {

            if (stream == self.inputStream) {
//                NSLog(@"NSStreamEventHasBytesAvailable");

                // if we have no current transfer active.. then read in a header
                if (currentByteOffset == 0) {
                    int payloadLength = [self readHeaderFromStream:self.inputStream];                
                    if (payloadLength == 0) return;
                    totalBytesInPayload = payloadLength;
                }
                
                // we can now read the payload data packet since we know how large it is...
                uint8_t payloadBytes[totalBytesInPayload - currentByteOffset];

                // read in our payload bytes. store this is in our payload bytes buffer.
				int numOfPayloadPacketsBytesRead = 0;
				numOfPayloadPacketsBytesRead = [self.inputStream read:payloadBytes maxLength:totalBytesInPayload - currentByteOffset];

                // if we failed then...
				if(numOfPayloadPacketsBytesRead <= 0) {
					if ([stream streamStatus] != NSStreamStatusAtEnd){
                    }
                } 
                else {
                    NSLog(@"numOfPayloadPacketsBytesRead = %i", numOfPayloadPacketsBytesRead);

                    currentByteOffset += numOfPayloadPacketsBytesRead;
                    [self.currentConnectionData appendBytes:payloadBytes length:numOfPayloadPacketsBytesRead];

                    NSLog(@"currentByteOffset %i", currentByteOffset);
                    NSLog(@"totalBytesInPayload %i", totalBytesInPayload);

                    if (currentByteOffset < totalBytesInPayload) {
                        // not enough bytes read. keep going.
                        return;
                    }

                    char *finalPayloadBytes = malloc(totalBytesInPayload);
                    memset(finalPayloadBytes, 0, totalBytesInPayload);
                    
                    // must NULL terminate our byte array to avoid garbage bytes at the end.
                    [self.currentConnectionData getBytes:finalPayloadBytes length:totalBytesInPayload];
                    finalPayloadBytes[totalBytesInPayload] = 0;

                    // create the tcpCommand response object from the read in payload bytes..
                    TCPCommand *tcpResponse = [[TCPCommand alloc] initWithPayloadBytes:(char *)finalPayloadBytes];

                    // notify the delegate that the command was received.
                    [self.delegate tcpConnection:self didReceiveCommand:tcpResponse];
                    [self.currentConnectionData setData:[NSData data]];

                    currentByteOffset = 0;
                    totalBytesInPayload = 0;
                }
			}

			break;
		}
        case NSStreamEventHasSpaceAvailable: {
            break;
        }
        case NSStreamEventNone:{
            break;
        }
		case NSStreamEventErrorOccurred: {            
			break;
		}
		case NSStreamEventEndEncountered: {
            [self.delegate tcpConnectionDidClose:self];			
            break;
		}
	}
}

- (int)readHeaderFromStream:(NSInputStream *)stream {
    // first declare the byte array that will hold the header packet.
    uint8_t *headerPacketBytes[sizeOfHeaderPacket];
    
    // then read our header packet bytes into the buffer.
    int numOfHeaderPacketsBytesRead = 0;
    numOfHeaderPacketsBytesRead = [stream read:(uint8_t *)headerPacketBytes maxLength:sizeOfHeaderPacket];
    
    // use this method of NSString to ensure that the byte array read in becomes NULL terminated..
    NSString *headerPacketAsString = [[NSString alloc] initWithBytes:headerPacketBytes length:numOfHeaderPacketsBytesRead encoding:NSUTF8StringEncoding];
//    NSLog(@"headerPacketAsString %@", headerPacketAsString);
    
    // if the header does not define a length of the payload, then just give up..
    int payloadLength = [headerPacketAsString intValue];
    
//    NSLog(@"payloadLength %i", payloadLength);
    
    return payloadLength;
}

- (void)openInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream {

    [self closeStreams];
    
    self.inputStream = inStream;
    self.outputStream = outStream;
 
    [self openStreams];
}

- (void)openStreams {
    
    self.inputStream.delegate = self;
	[self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.inputStream open];
	
    self.outputStream.delegate = self;
	[self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.outputStream open];
    
}

- (void)closeStreams {
    
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	self.inputStream = nil;
	inReady = NO;
    
	[self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	self.outputStream = nil;
	outReady = NO;
}

@end
