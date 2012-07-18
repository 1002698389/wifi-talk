//
//  TCPConnection.h
//  WifiTalk
//
//  Created by Joey Patino on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


/*
    This class represents a TCP socket connection and may be used to send and
    receive data across a local network. Please see TCPCommand for details
    on the data transport 'protocol'
*/

@class TCPCommand;
@class TCPConnection;
@protocol TCPConnectionDelegate <NSObject>

- (void)tcpConnection:(TCPConnection *)connection didReceiveCommand:(TCPCommand *)cmd;
- (void)tcpConnection:(TCPConnection *)connection didSendCommand:(TCPCommand *)cmd;

- (void)tcpConnectionDidOpen:(TCPConnection *)connection;
- (void)tcpConnectionDidClose:(TCPConnection *)connection;

@end


@interface TCPConnection : NSObject

@property (nonatomic, assign) BOOL inReady;
@property (nonatomic, assign) BOOL outReady;

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) NSMutableData *currentConnectionData;

@property (nonatomic, unsafe_unretained) NSObject <TCPConnectionDelegate> *delegate;

- (void)sendCommand:(TCPCommand *)cmd;
- (void)openInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream;
- (void)closeStreams;

@end
