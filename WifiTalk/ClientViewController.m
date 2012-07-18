//
//  ClientViewController.m
//  WifiTalk
//
//  Created by Joey Patino on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ClientViewController.h"
#import "TCPServer.h"
#import "TCPConnection.h"
#import "CommandBuilder.h"
#import "TCPCommand.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#import "AVMoviePlayerViewController.h"



#define kTCPCommandOne      @"TCP Command One"
#define kTCPCommandTwo      @"TCP Command Two"
#define kTCPCommandThree    @"TCP Command Three"
#define kTCPCommandFour     @"TCP Command Four"

@interface ClientViewController () <NSNetServiceBrowserDelegate, NSNetServiceDelegate, TCPConnectionDelegate, UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) IBOutlet UITextView *connectionLog;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIImageView *recievedImageView;

@property (nonatomic, strong) TCPConnection *connection;
@property (nonatomic, strong) NSURL *serverAddress;

@property (nonatomic, strong) NSMutableArray *services;
@property (nonatomic, strong) NSNetServiceBrowser *netServiceBrowser;
@property (nonatomic, strong) NSNetService *currentResolve;
@property (nonatomic, strong) NSString *previousConnectionName;

@property (nonatomic, strong) AVMoviePlayerViewController *moviePlayer;


- (BOOL)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain;
@end

@implementation ClientViewController
@synthesize services;
@synthesize serverAddress;

@synthesize connectionLog;
@synthesize tableView;
@synthesize recievedImageView;

@synthesize netServiceBrowser;
@synthesize connection;
@synthesize currentResolve;
@synthesize previousConnectionName;
@synthesize moviePlayer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

        self.services = [[NSMutableArray alloc] init];
        
        self.connection = [[TCPConnection alloc] init];
        self.connection.delegate = self;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![self searchForServicesOfType:[TCPServer bonjourTypeFromIdentifier:@"WifiTalk"] inDomain:@"local"]) {
        [self appendLogMessage:[NSString stringWithFormat:@"failed to search for bonjour service"]];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -

- (BOOL)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain {
	
	[self.netServiceBrowser stop];
	[self.services removeAllObjects];
    
	NSNetServiceBrowser *aNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
	if(!aNetServiceBrowser) {
        // The NSNetServiceBrowser couldn't be allocated and initialized.
		return NO;
	}
    
	aNetServiceBrowser.delegate = self;
	self.netServiceBrowser = aNetServiceBrowser;
	[self.netServiceBrowser searchForServicesOfType:type inDomain:domain];
    
	[self.tableView reloadData];
	return YES;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
	self.currentResolve = [self.services objectAtIndex:indexPath.row];
	[self.currentResolve setDelegate:self];
	[self.currentResolve resolveWithTimeout:0.0];
}

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// If there are no services and searchingForServicesString is set, show one row to tell the user.
    
	NSUInteger count = [self.services count];
	return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableview cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *tableCellIdentifier = @"UITableViewCell";
	UITableViewCell *cell = (UITableViewCell *)[tableview dequeueReusableCellWithIdentifier:tableCellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableCellIdentifier];
	}

	// Set up the text for the cell
	NSNetService *service = [self.services objectAtIndex:indexPath.row];
	cell.textLabel.text = [service name];
	cell.textLabel.textColor = [UIColor blackColor];

	return cell;
}

#pragma mark - 

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, aNetService.name);
    [self.services addObject:aNetService];

    if (!moreComing)
        [self.tableView reloadData];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, aNetService.name);

    [self.services removeObject:aNetService];
    
    if (!moreComing)
        [self.tableView reloadData];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.currentResolve = nil;
}

- (void)netServiceDidResolveAddress:(NSNetService *)service {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    NSInputStream *inStream = nil;
    NSOutputStream *outStream = nil;

    for (NSData* data in [service addresses]) {
        
        char addressBuffer[100];
        struct sockaddr_in* socketAddress = (struct sockaddr_in*) [data bytes];
        
        int sockFamily = socketAddress->sin_family;

        if (sockFamily == AF_INET || sockFamily == AF_INET6) {
            
            const char* addressStr = inet_ntop(sockFamily,
                                               &(socketAddress->sin_addr), addressBuffer,
                                               sizeof(addressBuffer));
            
            int port = ntohs(socketAddress->sin_port);
            
            if (addressStr && port) {

                if (sockFamily == 2) {
                    self.serverAddress = [NSURL URLWithString:[NSString stringWithFormat:@"%s:%d", addressStr, port]];

                    NSLog(@"self.serverAddress %@", self.serverAddress);

                    [self appendLogMessage:[NSString stringWithFormat:@"sockFamily %i", sockFamily]];
                    [self appendLogMessage:[NSString stringWithFormat:@"Found service at %s:%d", addressStr, port]];
                }
            }
        }
    }
    
    if ([service getInputStream:&inStream outputStream:&outStream]){
        [self appendLogMessage:[NSString stringWithFormat:@"Opening streams."]];
        [self.connection openInputStream:inStream outputStream:outStream];
        self.previousConnectionName = service.name;
    }
    else {
        [self appendLogMessage:[NSString stringWithFormat:@"failed to get input and output stream"]];
    }
    
    self.currentResolve = nil;
}

- (IBAction)sendCmdOne:(id)sender {
    [self.connection sendCommand:[CommandBuilder CommandWithName:@"GET_DIRECTORY" parameterValue:@"IPAD"]];
}

- (IBAction)sendCmdTwo:(id)sender {
    [self.connection sendCommand:[CommandBuilder CommandWithName:@"PLAY" parameterValue:nil]];
}

- (IBAction)sendCmdThree:(id)sender {
    [self.connection sendCommand:[CommandBuilder CommandWithName:@"STOP" parameterValue:nil]];
}

- (IBAction)sendCmdFour:(id)sender {
    [self.connection sendCommand:[CommandBuilder CommandWithName:kTCPCommandFour parameterValue:nil]];
}

#pragma mark -

- (void)tcpConnection:(TCPConnection *)connection didReceiveCommand:(TCPCommand *)cmd {

    [self appendLogMessage:[NSString stringWithFormat:@"Received command \"%@\"", cmd]];    
    [self handleCommand:cmd];
}

- (void)tcpConnection:(TCPConnection *)connection didSendCommand:(TCPCommand *)cmd {
    [self appendLogMessage:[NSString stringWithFormat:@"Sent command \"%@\"", cmd]];
}

- (void)tcpConnectionDidOpen:(TCPConnection *)connection {
    [self appendLogMessage:[NSString stringWithFormat:@"Connection opened"]];
}

- (void)tcpConnectionDidClose:(TCPConnection *)connection {
    [self appendLogMessage:[NSString stringWithFormat:@"Connection closed"]];
}

- (void)appendLogMessage:(NSString *)msg {
    [self.connectionLog setText:[NSString stringWithFormat:@"%@ - %@\n%@", [NSDate date], msg, self.connectionLog.text]];
}

#pragma mark -

- (void)handleCommand:(TCPCommand *)command {
    
    NSString *commandName = command.commandName;

    if ([commandName isEqualToString:@"GOODBYE"]) {
        [self.connection closeStreams];

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:[NSString stringWithFormat:@"%@. Attempt to reconnect?", command.parameter] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Retry", nil];
        [alert show];
    }
    else if ([commandName isEqualToString:@"PLAYBACK_BEGIN"]) {
        
    }
    else if ([commandName isEqualToString:@"PLAYBACK_TICK"]) {

    }
    else if ([commandName isEqualToString:@"PLAYBACK_STOP"]) {
        
    }
    else if ([commandName isEqualToString:@"DIRECTORY"]){
        
        NSString *urlString = [NSString stringWithFormat:@"http://%@/CONTENT/theFile.mp4", self.serverAddress];
        
        NSLog(@"url %@", urlString);
        
        [self.connection sendCommand:[CommandBuilder CommandWithName:@"DOWNLOAD" parameterValue:urlString]];
    }
    else if ([commandName isEqualToString:@"FILE_TRANSFER"]) {
                
        NSDictionary *parameters = (NSDictionary *)command.parameter;
//        
        NSString *command = [parameters objectForKey:@"FILE"];
        
        NSData *data = [NSString dataFromHexString:command];
        UIImage *img = [[UIImage alloc] initWithData:data];
        self.recievedImageView.image = img;

//        NSData *mp4Data = [NSString dataFromHexString:command];
//        
//        NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"movieFile.mp4"];
//        
//        if (![[NSFileManager defaultManager] createFileAtPath:filePath contents:mp4Data attributes:nil]){
//            NSLog(@"error saving file");
//        }
//        else {
//            NSLog(@"saved movie file to disk at path %@", filePath);
//        }
//        
//        if (self.moviePlayer == nil) {
//            NSLog(@"creating movie player");
//            self.moviePlayer = [[AVMoviePlayerViewController alloc] initWithURL:[NSURL fileURLWithPath:filePath]];
//            
//            __weak ClientViewController *weakSelf = self;
//            self.moviePlayer.didReachEndBlock = ^{
//                [weakSelf stopPlayback];
//            };
//            
//            self.moviePlayer.view.frame = self.view.bounds;
//            [self.view addSubview:self.moviePlayer.view];
//        }
    }
}

- (void)stopPlayback {

    [self.moviePlayer.moviePlayer seekToTime:kCMTimeZero];
    [self.moviePlayer.moviePlayer pause];    
}

#pragma mark -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            NSLog(@"Cancel");
            break;
        case 1: {
            NSLog(@"Retry");
            
            for (NSNetService *service in self.services){
            
                if ([service.name isEqualToString:self.previousConnectionName]){
                    self.currentResolve = service;
                    [self.currentResolve setDelegate:self];
                    [self.currentResolve resolveWithTimeout:2.0];
                    return;
                }
            }

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:alertView.message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Retry", nil];
            [alert show];
        }
            break;            
        default:
            break;
    }
}

@end
