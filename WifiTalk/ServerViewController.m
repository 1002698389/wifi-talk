//
//  ServerViewController.m
//  WifiTalk
//
//  Created by Joey Patino on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ServerViewController.h"
#import "TCPServer.h"
#import "TCPConnection.h"
#import "CommandBuilder.h"
#import "TCPCommand.h"

#import "AVMoviePlayerViewController.h"
#import "TCPDownloadRequestConnection.h"

@interface ServerViewController () <TCPServerDelegate, TCPConnectionDelegate>

@property (nonatomic, strong) TCPServer *server;
@property (nonatomic, strong) TCPConnection *connection;

@property (nonatomic, strong) IBOutlet UIButton *startStopButton;
@property (nonatomic, strong) IBOutlet UITextView *connectionLog;

@property (nonatomic, strong) IBOutlet UIView *movieView;
@property (nonatomic, strong) AVMoviePlayerViewController *moviePlayer;
@property (nonatomic, strong) id playBackTimeObserver;

@property (nonatomic, strong) TCPConnection *downloadConnection;
@end

@implementation ServerViewController
@synthesize server;
@synthesize connection;
@synthesize startStopButton;
@synthesize connectionLog;

@synthesize movieView;
@synthesize moviePlayer;
@synthesize playBackTimeObserver;
@synthesize downloadConnection;

#pragma mark -

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.server = [[TCPServer alloc] init];
        self.server.delegate = self;
    
        self.connection = [[TCPConnection alloc] init];
        self.connection.delegate = self;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - TCPServerDelegate

- (void) serverDidEnableBonjour:(TCPServer*)server withName:(NSString*)name {
    [self appendLogMessage:[NSString stringWithFormat:@"Started Server: \"%@\"", name]];
}

- (void) server:(TCPServer*)server didNotEnableBonjour:(NSDictionary *)errorDict {
    [self appendLogMessage:[NSString stringWithFormat:@"Failed to Start Server: \"%@\"", errorDict]];
}
//static int i = 0;
- (void) didAcceptConnectionForServer:(TCPServer*)server 
                          inputStream:(NSInputStream *)istr 
                         outputStream:(NSOutputStream *)ostr {

    NSLog(@"%s", __PRETTY_FUNCTION__);

    [self.connection openInputStream:istr outputStream:ostr];

//    if (i == 1) {
//        self.downloadConnection = [[TCPDownloadRequestConnection alloc] init];
//        self.downloadConnection.delegate = self;
//        [self.downloadConnection openInputStream:istr outputStream:ostr];
//    }
//
//    i++;
}

#pragma mark - TCPConnectionDelegate

- (void)tcpConnection:(TCPConnection *)connection didReceiveCommand:(TCPCommand *)cmd {
    [self appendLogMessage:[NSString stringWithFormat:@"Received command: \"%@\"", cmd]];

    [self handleCommand:cmd];
}

- (void)tcpConnection:(TCPConnection *)connection didSendCommand:(TCPCommand *)cmd {
    [self appendLogMessage:[NSString stringWithFormat:@"Sent command: \"%@\"", cmd]];
}

- (void)tcpConnectionDidOpen:(TCPConnection *)connection {

    [self appendLogMessage:[NSString stringWithFormat:@"Connection opened"]];
}

- (void)tcpConnectionDidClose:(TCPConnection *)connection {
    [self appendLogMessage:[NSString stringWithFormat:@"Connection closed"]];
}

#pragma mark - Actions

- (IBAction)startMovie:(UIButton *)sender {
    
    if (self.moviePlayer == nil) {
        self.moviePlayer = [[AVMoviePlayerViewController alloc] initWithURL:VideoURL];

        __weak ServerViewController *weakSelf = self;
        self.moviePlayer.didReachEndBlock = ^{
            [weakSelf stopPlayback];
        };
        
        self.moviePlayer.view.frame = self.movieView.bounds;
        [self.movieView addSubview:self.moviePlayer.view];
    }
    
    [self.moviePlayer.moviePlayer play];
    [self.connection sendCommand:[CommandBuilder CommandWithName:@"PLAYBACK_BEGIN"
                                                  parameterValue:nil]];
    
    NSTimeInterval interval = 1.0;

    self.playBackTimeObserver = [self.moviePlayer.moviePlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) 
                                                                                           queue:NULL 
                                                                                      usingBlock:^(CMTime time){

                                                                                          NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                                      [NSString stringWithFormat:@"%f", CMTimeGetSeconds(time)], @"CURRENT_TIME",
                                                                                                                      [self.moviePlayer.assetURL lastPathComponent], @"CURRENT_ASSET", nil];
                                                                                          
                                                                                          [self.connection sendCommand:[CommandBuilder CommandWithName:@"PLAYBACK_TICK" 
                                                                                                                                        parameterValue:parameters]];
                                                                                      }];
}

- (IBAction)startStopServer:(UIButton *)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (self.server.isRunning) {
        [self appendLogMessage:[NSString stringWithFormat:@"Server is running. Stopping now."]];
        [self.connection sendCommand:[CommandBuilder CommandWithName:@"GOODBYE" parameterValue:@"Your session has been terminated by the server."]];
        
        if ([self.server stop]) {
            [self appendLogMessage:[NSString stringWithFormat:@"Server is shutdown..."]];
        }
        else {
            [self appendLogMessage:[NSString stringWithFormat:@"Server failed to shutdown."]];
        }
        
        [self.startStopButton setTitle:@"Start" forState:UIControlStateNormal];
    }
    else {
        [self appendLogMessage:[NSString stringWithFormat:@"Starting server..."]];
        NSError *error = nil;
        [self.server start:&error];
        
        if (!error) {
            if(![self.server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:@"WifiTalk"] name:nil]) {
                return;
            }
            [self.startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
        }
        else {
            [self appendLogMessage:[NSString stringWithFormat:@"Failed to Enable Bonjour: \"%@\"", error]];
        }
    }
}

#pragma mark -

- (void)appendLogMessage:(NSString *)msg {
    [self.connectionLog setText:[NSString stringWithFormat:@"%@\n%@", msg, self.connectionLog.text]];
}

- (void)handleCommand:(TCPCommand *)command {

    NSString *commandName = command.commandName;
    
    if ([commandName isEqualToString:@"GET_DIRECTORY"]) {
        
        // This command is asking for the directory of files or folders. We can then send back a response. 
        [self.connection sendCommand:[CommandBuilder CommandWithName:@"DIRECTORY"
                                                      parameterValue:[NSArray arrayWithObjects:@"ITEM1", @"ITEM2", @"ITEM3", @"ITEM4", nil]]];
    }
    else if ([commandName isEqualToString:@"PLAY"]) {
        [self startMovie:nil];
    }
    else if ([commandName isEqualToString:@"STOP"]){
        [self stopPlayback];
    }
    else if ([commandName isEqualToString:@"DOWNLOAD"]){

//        NSLog(@"Will downoad file at URL %@", command.parameter);
//
//        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:command.parameter] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
//        
//        NSError *error = nil;
//        
//        NSData *d = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
//        
//        NSLog(@"did load data %@", d);
        
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Icon-72@2x" ofType:@"png"];
//        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"LRC_IPAD_square_1024x1024_Still1" ofType:@"png"];

        NSLog(@"filePath %@", filePath);
        
        NSData *fileData = [NSData dataWithContentsOfFile:filePath];
        
        NSLog(@"fileData.length %i", [fileData length]);
        
        NSString *fileDataAsString = [NSString stringFromHexData:fileData];
        
        NSDictionary *parameterDictionary = [NSDictionary dictionaryWithObjectsAndKeys:fileDataAsString, @"FILE", nil];
        
        [self.connection sendCommand:[CommandBuilder CommandWithName:@"FILE_TRANSFER"
                                                      parameterValue:parameterDictionary]];
    }    
}

- (void)stopPlayback {

    [self.moviePlayer.moviePlayer removeTimeObserver:self.playBackTimeObserver];
    [self.moviePlayer.moviePlayer seekToTime:kCMTimeZero];
    [self.moviePlayer.moviePlayer pause];
    self.playBackTimeObserver = nil;
    
    [self.connection sendCommand:[CommandBuilder CommandWithName:@"PLAYBACK_STOP"
                                                  parameterValue:nil]];
}

@end
