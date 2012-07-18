//
//  TCPDownloadRequestConnection.m
//  WifiTalk
//
//  Created by Joey Patino on 7/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TCPDownloadRequestConnection.h"

@interface TCPDownloadRequestConnection ()

@property (nonatomic, assign) CFHTTPMessageRef httpMessage;
@end

@implementation TCPDownloadRequestConnection
@synthesize httpMessage;

- (id)init {
    self = [super init];
    
    self.currentConnectionData = [NSMutableData data];
    self.httpMessage = CFHTTPMessageCreateEmpty(NULL, YES);
    
    return self;
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {

    switch(eventCode) {
		case NSStreamEventOpenCompleted: {

            NSLog(@"NSStreamEventOpenCompleted");
            
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
                NSLog(@"NSStreamEventHasBytesAvailable");
                uint8_t bytesReadIn[2048];
                int len = 0;
                len = [self.inputStream read:bytesReadIn maxLength:2048];
                
                NSLog(@"read %i bytes", len);

                [self.currentConnectionData appendBytes:bytesReadIn length:len];
                
                CFHTTPMessageAppendBytes(self.httpMessage, bytesReadIn, len);
                
                if (CFHTTPMessageIsHeaderComplete(self.httpMessage)){

                    NSDictionary *headerDictionary = (__bridge NSDictionary *)CFHTTPMessageCopyAllHeaderFields(self.httpMessage);
                    NSLog(@"headerDictionary %@", headerDictionary);
                    
                    NSURL *requestURL = (__bridge NSURL *)CFHTTPMessageCopyRequestURL(self.httpMessage);
                    NSLog(@"requestURL %@", requestURL);
                    
                    NSString *requestMethod = (__bridge NSString *)CFHTTPMessageCopyRequestMethod(self.httpMessage);
                    NSLog(@"requestMethod %@", requestMethod);
                    
                }
                else {
                    NSLog(@"header is not complete");
                }
			}
            
			break;
		}
        case NSStreamEventHasSpaceAvailable: {
                NSLog(@"NSStreamEventHasSpaceAvailable");
            break;
        }
        case NSStreamEventNone:{
                NSLog(@"NSStreamEventNone");
            break;
        }
		case NSStreamEventErrorOccurred: {
                NSLog(@"NSStreamEventErrorOccurred");
			break;
		}
		case NSStreamEventEndEncountered: {
                NSLog(@"NSStreamEventEndEncountered");
            [self.delegate tcpConnectionDidClose:self];			
            break;
		}
	}
}

@end
