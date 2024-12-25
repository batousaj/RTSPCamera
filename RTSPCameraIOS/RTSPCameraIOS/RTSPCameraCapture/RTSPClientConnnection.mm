//
//  RTSPClientConnection.m
//  live555-simple-demo-4-iOS
//
//  Created by Mac Mini 2021_1 on 4/7/24.
//  Copyright © 2024 TheFlyingPenguin. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#include <stdio.h>
#include <string.h>
#include <vector>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <netdb.h>
#include "nalu_rewriter.h"
#include "RTSPClientConnnection.h"

static NSString * _Nonnull const CRLF = @"\r\n";
static const int MAX_LINE_SIZE = 4098;
static NSString * DEFAULT_USER_AGENT = @"efcs.f58.29.100";

static uint8_t H26X_marker[] = { 0, 0, 0, 1};

// Function to create an SdpInfo instance
static SdpInfo createSdpInfo(NSString * _Nullable sessionName, NSString * _Nullable sessionDescription, VideoTrack * _Nullable videoTrack, AudioTrack * _Nullable audioTrack) {
    SdpInfo info;
    info.sessionName = sessionName;
    info.sessionDescription = sessionDescription;
    info.videoTrack = videoTrack;
    info.audioTrack = audioTrack;
    return info;
}

static const uint8_t NAL_PREFIX1[] = { 0x00, 0x00, 0x00, 0x01 };
static const uint8_t NAL_PREFIX2[] = { 0x00, 0x00, 0x01 };

uint8_t getH264NalUnitType(const uint8_t *data, NSUInteger offset, NSUInteger length) {
    if (data == NULL || length <= sizeof(NAL_PREFIX1)) {
        return (uint8_t)-1;
    }

    NSInteger nalUnitTypeOctetOffset = -1;
    if (data[offset + sizeof(NAL_PREFIX2) - 1] == 1) {
        nalUnitTypeOctetOffset = offset + sizeof(NAL_PREFIX2) - 1;
    } else if (data[offset + sizeof(NAL_PREFIX1) - 1] == 1) {
        nalUnitTypeOctetOffset = offset + sizeof(NAL_PREFIX1) - 1;
    }

    if (nalUnitTypeOctetOffset != -1) {
        uint8_t nalUnitTypeOctet = data[nalUnitTypeOctetOffset + 1];
        return (uint8_t)(nalUnitTypeOctet & 0x1f);
    } else {
        return (uint8_t)-1;
    }
}

@implementation Track

- (instancetype) init {
    self = [super init];
    if (self != nil) {}
    return self;
}

@end

@implementation VideoTrack

@synthesize payloadType;
@synthesize request;

- (instancetype) initWithCodec:(VideoCodec) codec {
    self = [super init];
    if (self != nil)
    {
        self.videoCodec = codec;
    }
    
    return self;
}

@end

@implementation AudioTrack

@synthesize payloadType;
@synthesize request;

- (instancetype) initWithCodec:(AudioCodecType) codec {
    self = [super init];
    if (self != nil)
    {
        self.audioCodec = codec;
    }
    
    return self;
}

@end

@implementation RTSPClientConnnection {
    NSString* _uriRtsp;
    
    BOOL _isRequestVideo;
    BOOL _isRequestAudio;
    
    NSString* _username;
    NSString* _password;
    NSString* _userAgent;
    
    int _socketHandle;
    std::vector<uint8_t> m_cfg;
    
    VideoRtpParser *videoParser;
    SdpInfo sdpInfo;
    int sessionTimeout;
    NSInteger capabilities;
    NSString *authToken;
    NSDictionary<NSString *, NSString *>* digestRealmNonce;
    __block int cSeq;
    NSString *session;
}

- (instancetype) initWithUrl:(NSString*) url {
    self = [super init];
    if (self != nil)
    {
        _uriRtsp = url;
        _userAgent = DEFAULT_USER_AGENT;
        _decoder = [[RTSPCapturerDecode alloc] init];
        _decoder.delegate = self;
        videoParser = [[VideoRtpParser alloc] init];
        authToken = nil;
        digestRealmNonce = nil;
        session = nil;
        sdpInfo = createSdpInfo(nil, nil, nil, nil);
        cSeq = 0;
        
        [self setupDecodedThread];
    }
    
    return self;
}

- (void) startWithUsername:(NSString*) username
                  password:(NSString*) password
              requestVideo:(BOOL) isVideo
              requestAudio:(BOOL) isAudio {
    _username = username;
    _password = password;
    _isRequestVideo = isVideo;
    _isRequestAudio = isAudio;
    
    [self processFrame];
}

- (void) startVideo {
    if (![self setupAddress]) {
        return;
    }
    
    [self setupStreamsWithClientSocket];
    [self startDecodeThread];
    [self startWithUsername:@""
                   password:@""
               requestVideo:YES
               requestAudio:NO];
}

- (void) startVideoWithUsername:(NSString*) username
                       password:(NSString*) password {
    if (![self setupAddress]) {
        return;
    }
    
    [self setupStreamsWithClientSocket];
    [self startDecodeThread];
    [self startWithUsername:username
                   password:password
               requestVideo:YES
               requestAudio:NO];
}

- (void) setupDecodedThread {
    self.decodeThread = [[NSThread alloc] initWithBlock:^{
        do {
            @autoreleasepool {
                [[NSRunLoop currentRunLoop] run];
            }
        } while (![NSThread currentThread].isCancelled);
    }];
    self.decodeThread.name = @"ScreenshareThread";
    self.decodeThread.qualityOfService = NSQualityOfServiceBackground;
}

- (void) startDecodeThread {
    [self.decodeThread start];
}

- (void) stopDecodeThread {
    [self.decodeThread cancel];
}

- (void) processFrame {
    [self performSelector:@selector(execute) onThread:self.decodeThread withObject:nil waitUntilDone:false];
}

- (BOOL)setupAddress {
    NSURL *rtspURL = [NSURL URLWithString:_uriRtsp];
    
    struct hostent *host_entry = gethostbyname([rtspURL.host UTF8String]);
    if (host_entry == NULL) {
        return NO;
    }
    
    char *ipAddress = inet_ntoa(*((struct in_addr *)host_entry->h_addr_list[0]));
    
    NSString *host = [NSString stringWithUTF8String:ipAddress];
    NSInteger port = rtspURL.port.integerValue;
    if (port == 0) {
        port = 554; // Default RTSP port
    }

    _socketHandle = socket(AF_INET, SOCK_STREAM, 0);
    if (_socketHandle < 0) {
         NSLog(@"Error: Could not create socket");
        return NO;
    }

    struct sockaddr_in serverAddr;
    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(port);

    if (inet_pton(AF_INET, [host UTF8String], &serverAddr.sin_addr) <= 0) {
        close(_socketHandle);
        NSLog(@"Error: Invalid server address");
        return NO;
    }

    if (connect(_socketHandle, (struct sockaddr *)&serverAddr, sizeof(serverAddr)) < 0) {
        close(_socketHandle);
        // NSLog(@"Error: Could not connect to server");
        return NO;
    }
    
    return YES;
}

- (void)setupStreamsWithClientSocket {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, _socketHandle, &readStream, &writeStream);
    
    CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);

    self.inputStream = (__bridge NSInputStream *)readStream;
    self.outputStream = (__bridge NSOutputStream *)writeStream;

    self.inputStream.delegate = self;
    self.outputStream.delegate = self;
    
    [self scheduleStreams];
        
    [self.inputStream open];
    [self.outputStream open];
}

- (void)scheduleStreams {
    _networkQueue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
    __weak RTSPClientConnnection* weakSelf = self;
    dispatch_async(_networkQueue, ^{
        [weakSelf.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [weakSelf.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

        // NSLog(@"streams scheduled");
        BOOL isRunning = NO;

        do {
            isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (isRunning);

        // NSLog(@"streams stopped");
    });
}

- (void)unscheduleStreams {
    if (_networkQueue == nil) {
        return;
    }
    
    // NSLog(@"unscheduleStreams");
    dispatch_sync(self.networkQueue, ^{
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    });
}

- (void) execute {
    [self.delegate onRtspConnecting];
    @try {
        NSArray<NSDictionary<NSString *, NSString *> *> *headers;
        int status;
        
        // Send OPTIONS command
        self.state = RTSPStateOptions;
        [self sendOptionsCommand:self.outputStream request:_uriRtsp cSeq:++cSeq userAgent:_userAgent authToken:nil];
        status = [self readResponseStatusCode:self.inputStream];
        headers = [self readResponseHeaders:self.inputStream];
        [self dumpHeaders:headers];
        // Try once again with credentials

        if (status == 401) {
            digestRealmNonce = [self getHeaderWwwAuthenticateDigestRealmAndNonce:headers];
            if (digestRealmNonce == nil) {
                NSString *basicRealm = [self getHeaderWwwAuthenticateBasicRealm:headers];
                if ([basicRealm length] == 0) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Unknown authentication type" userInfo:nil];
                }
                // Basic auth
                authToken = [self getBasicAuthHeaderWithUsername:_username password:_password];
            } else {
                // Digest auth
                authToken = [self getDigestAuthHeaderWithUsername:_username password:_password method:@"OPTIONS" request:_uriRtsp realm:digestRealmNonce.allValues.firstObject nonce:digestRealmNonce.allValues.lastObject];
            }
            [self sendOptionsCommand:self.outputStream request:_uriRtsp cSeq:++cSeq userAgent:_userAgent authToken:authToken];
            status = [self readResponseStatusCode:self.inputStream];
            headers = [self readResponseHeaders:self.inputStream];
            [self dumpHeaders:headers];
        }
        
        NSLog(@"OPTIONS status: %d", status);
        [self checkStatusCode:status];
        capabilities = [self getSupportedCapabilities:headers];
        
        // Send DESCRIBE command
        [self sendDescribeCommand:self.outputStream request:_uriRtsp cSeq:++cSeq userAgent:_userAgent authToken:authToken];
        status = [self readResponseStatusCode:self.inputStream];
        headers = [self readResponseHeaders:self.inputStream];
        [self dumpHeaders:headers];
        // Try once again with credentials
        if (status == 401) {
            digestRealmNonce = [self getHeaderWwwAuthenticateDigestRealmAndNonce:headers];
            if (digestRealmNonce == nil) {
                NSString *basicRealm = [self getHeaderWwwAuthenticateBasicRealm:headers];
                if ([basicRealm length] == 0) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Unknown authentication type" userInfo:nil];
                }
                // Basic auth
                authToken = [self getBasicAuthHeaderWithUsername:_username password:_password];
            } else {
                // Digest auth
                authToken = [self getDigestAuthHeaderWithUsername:_username password:_password method:@"DESCRIBE" request:_uriRtsp realm:digestRealmNonce.allValues.firstObject nonce:digestRealmNonce.allValues.lastObject];
            }
            [self sendDescribeCommand:self.outputStream request:_uriRtsp cSeq:++cSeq userAgent:_userAgent authToken:authToken];
            status = [self readResponseStatusCode:self.inputStream];
            headers = [self readResponseHeaders:self.inputStream];
            [self dumpHeaders:headers];
        }
        
        NSLog(@"DESCRIBE status: %d", status);
        [self checkStatusCode:status];
        NSInteger contentLength = [self getHeaderContentLength:headers];
        if (contentLength > 0) {
            NSString *content = [self readContentAsText:self.inputStream length:contentLength];
            NSLog(@"%@", content);
            NSArray<NSDictionary<NSString *, NSString *> *> *params = [self getDescribeParams:content];
            sdpInfo = [self getSdpInfoFromDescribeParams:params];
            if (!_isRequestVideo)
                sdpInfo.videoTrack = nil;
            if (!_isRequestAudio)
                sdpInfo.audioTrack = nil;
        }
        
        // Send SETUP commands
        sessionTimeout = 0;
        for (int i = 0; i < 2; i++) {
            // i=0 - video track, i=1 - audio track
            BOOL isRequest = i == 0 ? _isRequestVideo : _isRequestAudio;
            if (isRequest) {
                NSString *uriRtspSetup = _uriRtsp;
                if (uriRtspSetup == nil) {
                    // NSLog(@"%@", @"Failed to get RTSP URI for SETUP");
                    continue;
                }
                if (digestRealmNonce != nil)
                    authToken = [self getDigestAuthHeaderWithUsername:_username password:_password method:@"SETUP" request:uriRtspSetup realm:digestRealmNonce.allValues.firstObject nonce:digestRealmNonce.allValues.lastObject];
                [self sendSetupCommand:self.outputStream request:uriRtspSetup
                                  cSeq:++cSeq
                             userAgent:_userAgent
                               session:session
                             authToken:authToken
                           interleaved:(i == 0 ? @"0-1" : @"2-3")];
                status = [self readResponseStatusCode:self.inputStream];
                NSLog(@"SETUP status: %d", status);
                [self checkStatusCode:status];
                headers = [self readResponseHeaders:self.inputStream];
                [self dumpHeaders:headers];
                session = [self getHeader:headers header:@"Session"];
                if ([session length] > 0) {
                    NSArray<NSString *> *params = [session componentsSeparatedByString:@";"];
                    session = params[0];
                    // Getting session timeout
                    if ([params count] > 1) {
                        NSArray<NSString *> *timeoutParams = [params[1] componentsSeparatedByString:@"="];
                        if ([timeoutParams count] > 1) {
                            @try {
                                sessionTimeout = [timeoutParams[1] intValue];
                            } @catch (NSException *exception) {
                                 NSLog(@"%@", @"Failed to parse RTSP session timeout");
                            }
                        }
                    }
                }
                 NSLog(@"SETUP session: %@, timeout: %d", session, sessionTimeout);
                if ([session length] == 0)
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to get RTSP session" userInfo:nil];
            }
        }
        
        if ([session length] == 0)
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to get any media track" userInfo:nil];
        
        // Send PLAY command
        if (digestRealmNonce != nil)
            authToken = [self getDigestAuthHeaderWithUsername:_username password:_password method:@"PLAY" request:_uriRtsp realm:digestRealmNonce.allValues.firstObject nonce:digestRealmNonce.allValues.lastObject];
        [self sendPlayCommand:self.outputStream request:_uriRtsp cSeq:++cSeq userAgent:_userAgent session:session authToken:authToken];
        status = [self readResponseStatusCode:self.inputStream];
        NSLog(@"PLAY status: %d", status);
        [self checkStatusCode:status];
        headers = [self readResponseHeaders:self.inputStream];
        [self dumpHeaders:headers];
        [self.delegate onRtspConnected:sdpInfo];
        self.state = RTSPStatePlay;
        
        if (sdpInfo.videoTrack.sps != nil || sdpInfo.audioTrack != nil) {
            if (digestRealmNonce != nil)
                authToken = [self getDigestAuthHeaderWithUsername:_username password:_password method:(capabilities & RTSPCapabilityGetParameter) ? @"GET_PARAMETER" : @"OPTIONS" request:_uriRtsp realm:digestRealmNonce.allValues.firstObject nonce:digestRealmNonce.allValues.lastObject];
            NSString *authTokenFinal = authToken;
            NSString *sessionFinal = session;
            
            // Blocking call unless exitFlag set to true, thread.interrupt() called or connection closed.
            @try {
                [self readRtpDataWithInputStream:self.inputStream
                                keepAliveTimeout:sessionTimeout / 2 * 1000
                               keepAliveListener:^ {
                    // NSLog(@"%@", @"Sending keep-alive");
                    if (self->capabilities & RTSPCapabilityGetParameter)
                        [self sendGetParameterCommand:self.outputStream request:self->_uriRtsp cSeq:++self->cSeq userAgent:self->_userAgent session:sessionFinal authToken:authTokenFinal];
                    else
                        [self sendOptionsCommand:self.outputStream request:self->_uriRtsp cSeq:++self->cSeq userAgent:self->_userAgent authToken:authTokenFinal];
                }];
            } @finally {
                // Cleanup resources on server side
                if (capabilities & RTSPCapabilityTeardown) {
                    NSString* authToken = @"";
                    if (digestRealmNonce != nil)
                        authToken = [self getDigestAuthHeaderWithUsername:_username password:_password method:@"TEARDOWN" request:_uriRtsp realm:digestRealmNonce.allValues.firstObject nonce:digestRealmNonce.allValues.lastObject];
                    [self sendTeardownCommand:self.outputStream request:_uriRtsp cSeq:++cSeq userAgent:_userAgent session:sessionFinal authToken:authToken];
                    [self unscheduleStreams];
                }
            }
            [self.delegate onRtspDisconnecting];
            [self.delegate onRtspDisconnected];
        } else {
            [self.delegate onRtspFailed:@"No tracks found. RTSP server issue."];
        }
    } @catch (NSException *e) {
        [self.delegate onRtspFailed:e.reason];
    }
}


- (void)readRtpDataWithInputStream:(nonnull NSInputStream *)inputStream
                  keepAliveTimeout:(int)keepAliveTimeout
                 keepAliveListener:(void (^)())keepAliveListener {
    
//    uint8_t *data = 0;  Usually not bigger than MTU = 15KB
    
    NSData *nalUnitSps = sdpInfo.videoTrack ? sdpInfo.videoTrack.sps : nil;
    NSData *nalUnitPps = sdpInfo.videoTrack ? sdpInfo.videoTrack.pps : nil;
    
    long keepAliveSent = [[NSDate date] timeIntervalSince1970] * 1000;
    
    BOOL isLoop = true;
    while (isLoop) {
        
        RtpHeader* header = [self readHeader:inputStream];
        
        if (header == nil) {
            continue;
        }
        
        uint8_t * data = (uint8_t*)malloc(header.payloadSize);
        
        NSInteger bytes = [self.inputStream read:data maxLength:header.payloadSize];
        
        NSLog(@"Decode here");
        if (bytes <= 0) {
            continue;
        }
        
        long currentTime = [[NSDate date] timeIntervalSince1970] * 1000;
        if (keepAliveTimeout > 0 && currentTime - keepAliveSent > keepAliveTimeout) {
            keepAliveSent = currentTime;
            keepAliveListener();
        }
        
        if (sdpInfo.videoTrack && header.payloadType == sdpInfo.videoTrack.payloadType) {
            NSData *nalUnit = [videoParser processRtpPacketAndGetNalUnit:data length:header.payloadSize];
            if (nalUnit) {
                uint8_t type = getH264NalUnitType((uint8_t*)nalUnit.bytes, 0, nalUnit.length);
                if ( type == kSps) {
                    nalUnitSps = nalUnit;
                    
                } else if ( type == kPps) {
                    nalUnitPps = nalUnit;
                    
                }else if (type == kSei) {
                    //just ignore for now
                    
                }else {
                    if (nalUnitSps.bytes != nil && nalUnitPps.bytes != nil && type == kIdr) {
                        size_t size = nalUnitPps.length + nalUnitSps.length + nalUnit.length;
                        uint8_t * finalData = (uint8_t*)malloc(size);
                        memcpy(finalData, nalUnitSps.bytes, nalUnitSps.length);
//                        memcpy(finalData + nalUnitSps.length, nalUnitPps.bytes, nalUnitPps.length);
//                        memcpy(finalData + nalUnitSps.length + nalUnitPps.length, nalUnit.bytes, nalUnit.length);
                        [_decoder receivedRawVideoFrame:(uint8_t *)finalData withSize:size];
                    } else {
                        [_decoder receivedRawVideoFrame:(uint8_t *)nalUnit.bytes withSize: nalUnit.length];
                    }
                }
            }
        }
        free(data);
    }
}

- (RtpHeader*) readHeader:(NSInputStream *) inputStream {
    // 24 01 00 1c 80 c8 00 06  7f 1d d2 c4
    // 24 01 00 1c 80 c8 00 06  13 9b cf 60
    // 24 02 01 12 80 e1 01 d2  00 07 43 f0
    uint8_t header[RTP_HEADER_SIZE];
    // Skip 4 bytes (TCP only)
    NSInteger startBytes = [self readData:inputStream toBuffer:header offset:0 maxLength:4];

    if (header[0] == 0x24) {
        // NSLog(@"%@", header[1] == 0 ? @"RTP packet" : @"RTCP packet");
    }

    int packetSize = [RtpHeader getPacketSize:header];
    
    NSInteger bytes = [self readData:inputStream toBuffer:header offset:0 maxLength:RTP_HEADER_SIZE];
    
    if (bytes == RTP_HEADER_SIZE) {
        RtpHeader *rtpHeader = [RtpHeader parseData:header packetSize:packetSize];
        if (rtpHeader == nil) {
            // Header not found. Possible keep-alive response. Search for another RTP header.
            BOOL foundHeader = [RtpHeader searchForNextRtpHeader:inputStream header:header];
            if (foundHeader) {
                packetSize = [RtpHeader getPacketSize:header];
                NSInteger readBytes = [self readData:inputStream toBuffer:header offset:0 maxLength:RTP_HEADER_SIZE];
                if (readBytes == RTP_HEADER_SIZE) {
                    return [RtpHeader parseData:header packetSize:packetSize];
                }
            }
        } else {
            return rtpHeader;
        }
    }
    return nil;
}

- (void) handleNextState {
    switch (self.state) {
        case RTSPStateOptions: {
        }
        case RTSPStateDescribe: {
            break;
        }
        case RTSPStateSetup:
            break;
            
        case RTSPStatePlay:
            break;
    }
}

- (void) sendSimpleCommand:(NSString*) command
                    output:(NSOutputStream *) outputStream
                   request:(NSString *) request
                      cSeq:(int) cSeq
                 userAgent:(NSString *) userAgent
                   session:(NSString *) session
                 authToken:(NSString *) authToken {
    NSString *CRLF = @"\r\n";
    NSMutableData *data = [NSMutableData data];
    
    [data appendData:[[NSString stringWithFormat:@"%@ %@ RTSP/1.0%@", command, request, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (authToken != nil) {
        [data appendData:[[NSString stringWithFormat:@"Authorization: %@%@", authToken, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [data appendData:[[NSString stringWithFormat:@"CSeq: %d%@", cSeq, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (userAgent != nil) {
        [data appendData:[[NSString stringWithFormat:@"User-Agent: %@%@", userAgent, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    if (session != nil) {
        [data appendData:[[NSString stringWithFormat:@"Session: %@%@", session, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [data appendData:[CRLF dataUsingEncoding:NSUTF8StringEncoding]];
    
    // NSLog(@"data %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    [outputStream write:(const uint8_t *)[data bytes] maxLength:[data length]];
//    [outputStream close];
}

// Other command functions...

-(void) sendOptionsCommand:(NSOutputStream *) outputStream
                   request:(NSString *) request
                      cSeq:(int) cSeq
                 userAgent:(NSString *) userAgent
                 authToken:(NSString *) authToken {
    // NSLog(@"sendOptionsCommand(request=\"%@\", cSeq=%d)", request, cSeq);
    [self sendSimpleCommand:@"OPTIONS"
                     output:outputStream
                    request:request
                       cSeq:cSeq
                  userAgent:userAgent
                    session:nil
                  authToken:authToken];
}

-(void) sendGetParameterCommand:(NSOutputStream *) outputStream
                        request:(NSString *) request
                           cSeq:(int) cSeq
                      userAgent:(NSString *) userAgent
                        session:(NSString *) session
                      authToken:(NSString *) authToken {
    // NSLog(@"sendGetParameterCommand(request=\"%@\", cSeq=%d)", request, cSeq);
    [self sendSimpleCommand:@"GET_PARAMETER"
                     output:outputStream
                    request:request
                       cSeq:cSeq
                  userAgent:userAgent
                    session:session
                  authToken:authToken];
}

-(void) sendDescribeCommand:(NSOutputStream *) outputStream
                    request:(NSString *) request
                       cSeq:(int) cSeq
                  userAgent:(NSString *) userAgent
                  authToken:(NSString *) authToken {
    // NSLog(@"sendDescribeCommand(request=\"%@\", cSeq=%d)", request, cSeq);
    NSMutableData *data = [NSMutableData data];
    NSString *CRLF = @"\r\n";
    
    [data appendData:[[NSString stringWithFormat:@"DESCRIBE %@ RTSP/1.0%@", request, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendData:[[NSString stringWithFormat:@"Accept: application/sdp%@", CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (authToken != nil) {
        [data appendData:[[NSString stringWithFormat:@"Authorization: %@%@", authToken, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [data appendData:[[NSString stringWithFormat:@"CSeq: %d%@", cSeq, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (userAgent != nil) {
        [data appendData:[[NSString stringWithFormat:@"User-Agent: %@%@", userAgent, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [data appendData:[CRLF dataUsingEncoding:NSUTF8StringEncoding]];
    
    [outputStream write:(const uint8_t *)[data bytes] maxLength:[data length]];
//    [outputStream close];
}

-(void) sendTeardownCommand:(NSOutputStream *) outputStream
                    request:(NSString *) request
                       cSeq:(int) cSeq
                  userAgent:(NSString *) userAgent
                    session:(NSString *) session
                  authToken:(NSString *) authToken {
    // NSLog(@"sendTeardownCommand(request=\"%@\", cSeq=%d)", request, cSeq);
    NSMutableData *data = [NSMutableData data];
    NSString *CRLF = @"\r\n";
    
    [data appendData:[[NSString stringWithFormat:@"TEARDOWN %@ RTSP/1.0%@", request, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (authToken != nil) {
        [data appendData:[[NSString stringWithFormat:@"Authorization: %@%@", authToken, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [data appendData:[[NSString stringWithFormat:@"CSeq: %d%@", cSeq, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (userAgent != nil) {
        [data appendData:[[NSString stringWithFormat:@"User-Agent: %@%@", userAgent, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    if (session != nil) {
        [data appendData:[[NSString stringWithFormat:@"Session: %@%@", session, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [data appendData:[CRLF dataUsingEncoding:NSUTF8StringEncoding]];
    
    [outputStream write:(const uint8_t *)[data bytes] maxLength:[data length]];
//    [outputStream close];
}

-(void) sendSetupCommand:(NSOutputStream *) outputStream
                 request:(NSString *) request
                    cSeq:(int) cSeq
               userAgent:(NSString *) userAgent
                 session:(NSString *) session
               authToken:(NSString *) authToken
             interleaved:(NSString *) interleaved {
    // NSLog(@"sendSetupCommand(request=\"%@\", cSeq=%d)", request, cSeq);
    NSMutableData *data = [NSMutableData data];
    NSString *CRLF = @"\r\n";
    
    [data appendData:[[NSString stringWithFormat:@"SETUP %@ RTSP/1.0%@", request, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendData:[[NSString stringWithFormat:@"Transport: RTP/AVP/TCP;unicast;interleaved=%@%@", interleaved, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (authToken != nil) {
        [data appendData:[[NSString stringWithFormat:@"Authorization: %@%@", authToken, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [data appendData:[[NSString stringWithFormat:@"CSeq: %d%@", cSeq, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (userAgent != nil) {
        [data appendData:[[NSString stringWithFormat:@"User-Agent: %@%@", userAgent, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    if (session != nil) {
        [data appendData:[[NSString stringWithFormat:@"Session: %@%@", session, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [data appendData:[CRLF dataUsingEncoding:NSUTF8StringEncoding]];
    
    [outputStream write:(const uint8_t *)[data bytes] maxLength:[data length]];
//    [outputStream close];
}

-(void) sendPlayCommand:(NSOutputStream *) outputStream
                request:(NSString *) request
                   cSeq:(int) cSeq
              userAgent:(NSString *) userAgent
                session:(NSString *) session
              authToken:(NSString *) authToken {
    // NSLog(@"sendPlayCommand(request=\"%@\", cSeq=%d)", request, cSeq);
    NSMutableData *data = [NSMutableData data];
    NSString *CRLF = @"\r\n";
    
    [data appendData:[[NSString stringWithFormat:@"PLAY %@ RTSP/1.0%@", request, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    [data appendData:[[NSString stringWithFormat:@"Range: npt=0.000-%@", CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (authToken != nil) {
        [data appendData:[[NSString stringWithFormat:@"Authorization: %@%@", authToken, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [data appendData:[[NSString stringWithFormat:@"CSeq: %d%@", cSeq, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (userAgent != nil) {
        [data appendData:[[NSString stringWithFormat:@"User-Agent: %@%@", userAgent, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [data appendData:[[NSString stringWithFormat:@"Session: %@%@", session, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [data appendData:[CRLF dataUsingEncoding:NSUTF8StringEncoding]];
    
    [outputStream write:(const uint8_t *)[data bytes] maxLength:[data length]];
//    [outputStream close];
}

- (int)readResponseStatusCode:(NSInputStream *)inputStream {
    const char *rtspHeader = "RTSP/1.0 ";
    
    // Search for "RTSP/1.0 "
    BOOL readBytes = [self readUntilBytesFound:inputStream array:rtspHeader];
    NSString *line = [self readLine:inputStream];
    while (readBytes && line) {
        NSUInteger indexCode = [line rangeOfString:@" "].location;
        NSString *code = [line substringToIndex:indexCode];
        @try {
            int statusCode = [code intValue];
            return statusCode;
        } @catch (NSException *exception) {
            // Does not fulfill standard "RTSP/1.1 200 OK" token
            // Continue search for
        }
    }
    return -1;
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)readResponseHeaders:(NSInputStream *)inputStream {
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *headers = [NSMutableArray array];
    NSString *line = @"";
    do {
        line = [self readLine:inputStream];
        if ([line isEqualToString:@"\r\n"]) {
            return [headers copy];
        } else {
            NSArray<NSString *> *pairs = [line componentsSeparatedByString:@":"];
            if (pairs.count == 2) {
                [headers addObject:@{[pairs[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]:
                                         [pairs[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]}];
            }
        }
    } while (![line isEqualToString:@""]);
    
    return [headers copy];
}

- (NSArray<Track*> *)getTracksFromDescribeParams:(NSArray<NSDictionary<NSString *, NSString *> *> *)params {
    NSMutableArray<Track*> *tracks = [NSMutableArray arrayWithCapacity:2];
    Track* currentTrack = nil;
    for (NSDictionary<NSString *, NSString *> *param in params) {
        NSString *key = param.allKeys.firstObject;
        NSString *value = param[key];
        if ([key isEqualToString:@"m"]) {
            // m=video 0 RTP/AVP 96
            if ([value hasPrefix:@"video"]) {
                currentTrack = [VideoTrack new];
                [tracks addObject:currentTrack];
                // m=audio 0 RTP/AVP 97
            } else if ([value hasPrefix:@"audio"]) {
                currentTrack = [AudioTrack new];
                [tracks addObject:currentTrack];
            } else {
                currentTrack = nil;
            }
            if (currentTrack != nil) {
                // m=<media> <port>/<number of ports> <proto> <fmt> ...
                NSArray<NSString *> *values = [value componentsSeparatedByString:@" "];
                currentTrack.payloadType = (values.count > 3 ? [values[3] intValue] : -1);
                if (currentTrack.payloadType == -1) {
                    // NSLog(@"Failed to get payload type from \"m=%@\"", value);
                }
            }
        } else if ([key isEqualToString:@"a"]) {
            // a=control:trackID=1
            if (currentTrack != nil) {
                if ([value hasPrefix:@"control:"]) {
                    currentTrack.request = [value substringFromIndex:8];
                } else if ([value hasPrefix:@"fmtp:"]) {
                    // Video
                    if ([currentTrack isKindOfClass:[VideoTrack class]]) {
                        [self updateVideoTrackFromDescribeParam:(VideoTrack *)currentTrack param:param];
                        // Audio
                    } else {
                        [self updateAudioTrackFromDescribeParam:(AudioTrack *)currentTrack param:param];
                    }
                } else if ([value hasPrefix:@"rtpmap:"]) {
                    // Video
                    if ([currentTrack isKindOfClass:[VideoTrack class]]) {
                        NSArray<NSString *> *values = [value componentsSeparatedByString:@" "];
                        if (values.count > 1) {
                            values = [values[1] componentsSeparatedByString:@"/"];
                            if (values.count > 0) {
                                if ([values[0] caseInsensitiveCompare:@"h264"] == NSOrderedSame) {
                                    ((VideoTrack *)currentTrack).videoCodec = VideoCodecH264;
                                } else if ([values[0] caseInsensitiveCompare:@"h265"] == NSOrderedSame) {
                                    ((VideoTrack *)currentTrack).videoCodec = VideoCodecH265;
                                } else {
                                    // NSLog(@"Unknown video codec \"%@\"", values[0]);
                                }
                                // NSLog(@"Video: %@", values[0]);
                            }
                        }
                        // Audio
                    } else {
                        NSArray<NSString *> *values = [value componentsSeparatedByString:@" "];
                        if (values.count > 1) {
                            values = [values[1] componentsSeparatedByString:@"/"];
                            if (values.count > 1) {
                                AudioTrack *track = (AudioTrack *)currentTrack;
                                if ([values[0] caseInsensitiveCompare:@"mpeg4-generic"] == NSOrderedSame) {
                                    track.audioCodec = AudioCodecAAC;
                                } else if ([values[0] caseInsensitiveCompare:@"opus"] == NSOrderedSame) {
                                    track.audioCodec = AudioCodecOpus;
                                } else {
                                    // NSLog(@"Unknown audio codec \"%@\"", values[0]);
                                    track.audioCodec = AudioCodecUnknown;
                                }
                                track.sampleRateHz = [values[1] intValue];
                                // If no channels specified, use mono, e.g. "a=rtpmap:97 MPEG4-GENERIC/8000"
                                track.channels = (values.count > 2 ? [values[2] intValue] : 1);
                                // NSLog(@"Audio: %@, sample rate: %d Hz, channels: %d", [self getAudioCodecName:track.audioCodec], track.sampleRateHz, track.channels);
                            }
                        }
                    }
                }
            }
        }
    }
    return [tracks copy];
}

-(NSString * _Nullable) getUriForSetup:(NSString * _Nonnull) uriRtsp track:(Track* _Nullable) track {
    if (track == nil || [track.request isEqualToString:@""]) {
        return nil;
    }
    
    NSString *uriRtspSetup = uriRtsp;
    if ([track.request hasPrefix:@"rtsp://"] || [track.request hasPrefix:@"rtsps://"]) {
        // Absolute URL
        uriRtspSetup = track.request;
    } else {
        // Relative URL
        if (![track.request hasPrefix:@"/"]) {
            track.request = [NSString stringWithFormat:@"/%@", track.request];
        }
        uriRtspSetup = [uriRtsp stringByAppendingString:track.request];
    }
    return uriRtspSetup;
}

-(NSString * _Nullable) getAudioCodecName:(AudioCodecType) codec {
    switch (codec) {
        case AudioCodecAAC:
            return @"AAC";
        case AudioCodecOpus:
            return @"Opus";
        default:
            return @"Unknown";
    }
}

- (void) checkStatusCode:(int) code {
    switch (code) {
        case 200:
            break;
        case 401:
            @throw [NSException exceptionWithName:@"UnauthorizedException" reason:nil userInfo:nil];
        default:
            @throw [NSException exceptionWithName:@"IOException" reason:[NSString stringWithFormat:@"Invalid status code %d", code] userInfo:nil];
    }
}

- (BOOL) hasCapability:(RTSPCapability) capability capabilitiesMask:(NSUInteger) capabilitiesMask {
    return (capabilitiesMask & capability) != 0;
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)getDescribeParams:(NSString *)text {
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *list = [NSMutableArray array];
    NSArray<NSString *> *params = [text componentsSeparatedByString:@"\r\n"];
    for (NSString *param in params) {
        NSRange range = [param rangeOfString:@"="];
        if (range.location != NSNotFound) {
            NSString *name = [[param substringToIndex:range.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *value = [param substringFromIndex:range.location + 1];
            [list addObject:@{name: value}];
        }
    }
    return [list copy];
}

- (SdpInfo)getSdpInfoFromDescribeParams:(NSArray<NSDictionary<NSString *, NSString *> *> *)params {
    VideoTrack* videoTrack = nil;
    AudioTrack* audioTrack = nil;
    NSString* sessionName = @"";
    NSString* sessionDescription = @"";
    
    NSArray<Track*> *tracks = [self getTracksFromDescribeParams:params];
    
    for (Track* track in tracks) {
        if ([track isKindOfClass:[VideoTrack class]]) {
            videoTrack = (VideoTrack *)track;
        }
        
        if ([track isKindOfClass:[AudioTrack class]]) {
            audioTrack = (AudioTrack *)track;
        }
    }
    
    for (NSDictionary<NSString *, NSString *> *param in params) {
        NSString *key = param.allKeys.firstObject;
        NSString *value = param[key];
        if ([key isEqualToString:@"s"]) {
            sessionName = value;
        } else if ([key isEqualToString:@"i"]) {
            sessionDescription = value;
        }
    }
    
    SdpInfo sdpInfo = createSdpInfo(sessionName, sessionDescription, videoTrack, audioTrack);
    return sdpInfo;
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)getSdpAParams:(NSDictionary<NSString *, NSString *> *)param {
    NSString *key = param.allKeys.firstObject;
    NSString *value = param[key];
    
    if ([key isEqualToString:@"a"] && [value hasPrefix:@"fmtp:"] && value.length > 8) {
        NSString *trimmedValue = [[value substringFromIndex:8] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray<NSString *> *paramsA = [trimmedValue componentsSeparatedByString:@";"];
        NSMutableArray<NSDictionary<NSString *, NSString *> *> *retParams = [NSMutableArray array];
        for (NSString *paramA in paramsA) {
            NSString* paramAFinal = [paramA stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSRange range = [paramAFinal rangeOfString:@"="];
            if (range.location != NSNotFound) {
                NSString *name = [paramAFinal substringToIndex:range.location];
                NSString *value = [paramAFinal substringFromIndex:range.location + 1];
                [retParams addObject:@{name: value}];
            }
        }
        return [retParams copy];
    } else {
        // NSLog(@"Not a valid fmtp");
    }
    return nil;
}

- (void)updateVideoTrackFromDescribeParam:(VideoTrack *)videoTrack param:(NSDictionary<NSString *, NSString *> *)param {
    NSArray<NSDictionary<NSString *, NSString *> *> *params = [self getSdpAParams:param];
    if (params != nil) {
        for (NSDictionary<NSString *, NSString *> *pair in params) {
            NSString *key = pair.allKeys.firstObject;
            NSString *value = pair[key];
            if ([key.lowercaseString isEqualToString:@"sprop-parameter-sets"]) {
                NSArray<NSString *> *paramsSpsPps = [value componentsSeparatedByString:@","];
                if (paramsSpsPps.count > 1) {
                    NSData *sps = [[NSData alloc] initWithBase64EncodedString:paramsSpsPps[0] options:0];
                    NSData *pps = [[NSData alloc] initWithBase64EncodedString:paramsSpsPps[1] options:0];
                    NSMutableData *nalSps = [NSMutableData dataWithCapacity:sps.length + 4];
                    NSMutableData *nalPps = [NSMutableData dataWithCapacity:pps.length + 4];
                    uint8_t nalHeader[4] = {0, 0, 0, 1};
                    [nalSps appendBytes:nalHeader length:4];
                    [nalSps appendData:sps];
                    [nalPps appendBytes:nalHeader length:4];
                    [nalPps appendData:pps];
                    videoTrack.sps = nalSps;
                    videoTrack.pps = nalPps;
                }
            }
        }
    }
}

- (NSData *)getBytesFromHexString:(NSString *)config {
    NSMutableData *data = [NSMutableData data];
    int idx;
    for (idx = 0; idx + 2 <= config.length; idx += 2) {
        NSString *hexStr = [config substringWithRange:NSMakeRange(idx, 2)];
        NSScanner *scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        if ([scanner scanHexInt:&intValue]) {
            uint8_t byte = (uint8_t)intValue;
            [data appendBytes:&byte length:1];
        }
    }
    return data;
}

- (void)updateAudioTrackFromDescribeParam:(AudioTrack *)audioTrack param:(NSDictionary<NSString *, NSString *> *)param {
    NSArray<NSDictionary<NSString *, NSString *> *> *params = [self getSdpAParams:param];
    if (params != nil) {
        for (NSDictionary<NSString *, NSString *> *pair in params) {
            NSString *key = pair.allKeys.firstObject;
            NSString *value = pair[key];
            if ([key.lowercaseString isEqualToString:@"mode"]) {
                audioTrack.mode = value;
            } else if ([key.lowercaseString isEqualToString:@"config"]) {
                audioTrack.config = [self getBytesFromHexString:value];
            }
        }
    }
}

- (NSInteger) getHeaderContentLength:(NSArray<NSDictionary<NSString *, NSString *> *> *) headers {
    NSString *length = [self getHeader:headers header:@"content-length"];
    if (![length isEqualToString:@""]) {
        @try {
            return [length intValue];
        } @catch (NSException *exception) {
        }
    }
    return -1;
}

- (NSInteger) getSupportedCapabilities:(NSArray<NSDictionary<NSString *, NSString *> *> *)headers {
    for (NSDictionary<NSString *, NSString *> *head in headers) {
        NSString *h = [head.allKeys.firstObject lowercaseString];
        // Public: OPTIONS, DESCRIBE, SETUP, PLAY, GET_PARAMETER, SET_PARAMETER, TEARDOWN
        if ([h isEqualToString:@"public"]) {
            NSInteger mask = 0;
            NSArray<NSString *> *tokens = [[head.allValues.firstObject lowercaseString] componentsSeparatedByString:@","];
            for (NSString *token in tokens) {
                NSString* tokenFinal = [token stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if ([tokenFinal isEqual: @"options"]) {
                    mask |= RTSPCapabilityOptions;
                } else if ([tokenFinal isEqual: @"describe"]) {
                    mask |= RTSPCapabilityDescribe;
                } else if ([tokenFinal isEqual: @"announce"]) {
                    mask |= RTSPCapabilityAnnounce;
                } else if ([tokenFinal isEqual: @"setup"]) {
                    mask |= RTSPCapabilitySetup;
                } else if ([tokenFinal isEqual: @"play"]) {
                    mask |= RTSPCapabilityPlay;
                } else if ([tokenFinal isEqual: @"record"]) {
                    mask |= RTSPCapabilityRecord;
                } else if ([tokenFinal isEqual: @"pause"]) {
                    mask |= RTSPCapabilityPause;
                } else if ([tokenFinal isEqual: @"pause"]) {
                    mask |= RTSPCapabilityPause;
                } else if ([tokenFinal isEqual: @"teardown"]) {
                    mask |= RTSPCapabilityTeardown;
                } else if ([tokenFinal isEqual: @"set_parameter"]) {
                    mask |= RTSPCapabilitySetParameter;
                } else if ([tokenFinal isEqual: @"get_parameter"]) {
                    mask |= RTSPCapabilityGetParameter;
                } else {
                    mask |= RTSPCapabilityRedirect;
                }
            }
            return mask;
        }
    }
    return RTSPCapabilityNone;
}

- (NSDictionary<NSString *, NSString *> *)getHeaderWwwAuthenticateDigestRealmAndNonce:(NSArray<NSDictionary<NSString *, NSString *> *> *) headers {
    for (NSDictionary<NSString *, NSString *> *head in headers) {
        NSString *h = [head.allKeys.firstObject lowercaseString];
        // WWW-Authenticate: Digest realm="AXIS_00408CEF081C", nonce="00054cecY7165349339ae05f7017797d6b0aaad38f6ff45", stale=FALSE
        // WWW-Authenticate: Basic realm="AXIS_00408CEF081C"
        // WWW-Authenticate: Digest realm="Login to 4K049EBPAG1D7E7", nonce="de4ccb15804565dc8a4fa5b115695f4f"
        if ([h isEqualToString:@"www-authenticate"] && [[head.allValues.firstObject lowercaseString] hasPrefix:@"digest"]) {
            NSString *v = [[head.allValues.firstObject substringFromIndex:7] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSUInteger begin, end;
            
            begin = [v rangeOfString:@"realm="].location;
            begin = [v rangeOfString:@"\"" options:0 range:NSMakeRange(begin, v.length - begin)].location + 1;
            end = [v rangeOfString:@"\"" options:0 range:NSMakeRange(begin, v.length - begin)].location;
            NSString *digestRealm = [v substringWithRange:NSMakeRange(begin, end - begin)];
            
            begin = [v rangeOfString:@"nonce="].location;
            begin = [v rangeOfString:@"\"" options:0 range:NSMakeRange(begin, v.length - begin)].location + 1;
            end = [v rangeOfString:@"\"" options:0 range:NSMakeRange(begin, v.length - begin)].location;
            NSString *digestNonce = [v substringWithRange:NSMakeRange(begin, end - begin)];
            
            return @{@"realm": digestRealm, @"nonce": digestNonce};
        }
    }
    return nil;
}

- (NSString * )getHeaderWwwAuthenticateBasicRealm:(NSArray<NSDictionary<NSString *, NSString *> *> *)headers {
    for (NSDictionary<NSString *, NSString *> *head in headers) {
        NSString *h = [head.allKeys.firstObject lowercaseString];
        NSString *v = [head.allValues.firstObject lowercaseString];
        // Session: ODgyODg3MjQ1MDczODk3NDk4Nw
        // WWW-Authenticate: Digest realm="AXIS_00408CEF081C", nonce="00054cecY7165349339ae05f7017797d6b0aaad38f6ff45", stale=FALSE
        // WWW-Authenticate: Basic realm="AXIS_00408CEF081C"
        if ([h isEqualToString:@"www-authenticate"] && [v hasPrefix:@"basic"]) {
            v = [[v substringFromIndex:6] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            // realm=
            // AXIS_00408CEF081C
            NSArray<NSString *> *tokens = [v componentsSeparatedByString:@"\""];
            if (tokens.count > 2) {
                return tokens[1];
            }
        }
    }
    return nil;
}

// Basic authentication
- (NSString *)getBasicAuthHeaderWithUsername:(NSString*) username password:(NSString*) password {
    NSString *auth = [NSString stringWithFormat:@"%@:%@", (username ?: @""), (password ?: @"")];
    NSData *authData = [auth dataUsingEncoding:NSISOLatin1StringEncoding];
    return [NSString stringWithFormat:@"Basic %@", [authData base64EncodedStringWithOptions:0]];
}

// Digest authentication
- (NSString *)getDigestAuthHeaderWithUsername:(NSString*) username
                                     password:(NSString*) password
                                       method:(NSString*) method
                                      request:(NSString*) digestUri
                                        realm:(NSString*) realm
                                        nonce:(NSString *) nonce {
    @try {
        NSMutableData *ha1 = [NSMutableData dataWithLength:CC_MD5_DIGEST_LENGTH];
        NSMutableData *ha2 = [NSMutableData dataWithLength:CC_MD5_DIGEST_LENGTH];
        NSMutableData *ha3 = [NSMutableData dataWithLength:CC_MD5_DIGEST_LENGTH];
        CC_MD5_CTX md5;
        
        if (!username) username = @"";
        if (!password) password = @"";
        
        // calc A1 digest
        CC_MD5_Init(&md5);
        CC_MD5_Update(&md5, [username UTF8String], (CC_LONG)[username lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        CC_MD5_Update(&md5, ":", 1);
        CC_MD5_Update(&md5, [realm UTF8String], (CC_LONG)[realm lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        CC_MD5_Update(&md5, ":", 1);
        CC_MD5_Update(&md5, [password UTF8String], (CC_LONG)[password lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        CC_MD5_Final((unsigned char*)ha1.bytes, &md5);
        
        // calc A2 digest
        CC_MD5_Init(&md5);
        CC_MD5_Update(&md5, [method UTF8String], (CC_LONG)[method lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        CC_MD5_Update(&md5, ":", 1);
        CC_MD5_Update(&md5, [digestUri UTF8String], (CC_LONG)[digestUri lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        CC_MD5_Final((unsigned char*)ha2.bytes, &md5);
        
        // calc response
        CC_MD5_Init(&md5);
        CC_MD5_Update(&md5, [[self getHexStringFromBytes:ha1] UTF8String], (CC_LONG)[[self getHexStringFromBytes:ha1] lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        CC_MD5_Update(&md5, ":", 1);
        CC_MD5_Update(&md5, [nonce UTF8String], (CC_LONG)[nonce lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        CC_MD5_Update(&md5, ":", 1);
        CC_MD5_Update(&md5, [[self getHexStringFromBytes:ha2] UTF8String], (CC_LONG)[[self getHexStringFromBytes:ha2] lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
        CC_MD5_Final((unsigned char*)ha3.bytes, &md5);
        
        NSString* response = [self getHexStringFromBytes:ha3];
        
        return [NSString stringWithFormat:@"Digest username=\"%@\", realm=\"%@\", nonce=\"%@\", uri=\"%@\", response=\"%@\"",
                username, realm, nonce, digestUri, response];
    } @catch (NSException *exception) {
        // NSLog(@"Exception: %@", exception);
    }
    return nil;
}

- (NSString *)getHexStringFromBytes:(NSData *)bytes {
    const unsigned char *dataBuffer = (const unsigned char *)[bytes bytes];
    if (!dataBuffer) return [NSString string];
    NSUInteger dataLength = [bytes length];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendFormat:@"%02x", dataBuffer[i]];
    }
    return hexString;
}

- (NSString *)readContentAsText:(NSInputStream *)inputStream length:(NSInteger) length {
    if (length <= 0) return @"";
    uint8_t b[length];
    NSInteger read = [self readData:inputStream toBuffer:b offset:0 maxLength:length];
    return [[NSString alloc] initWithBytes:b length:read encoding:NSUTF8StringEncoding];
}

- (void) shiftLeftArra:(uint8_t *)array num:(NSInteger) num {
    // ABCDEF -> BCDEF
    if (num - 1 >= 0) {
        memmove(array, array + 1, num - 1);
    }
}

- (BOOL) readUntilBytesFound:(NSInputStream *)inputStream
                       array:(const char *)array {
    uint8_t buffer[sizeof(array)];
    // Fill in buffer
    if ([self readData:inputStream toBuffer:buffer offset:0 maxLength:sizeof(buffer)] != sizeof(buffer)) return NO; // EOF
    
    BOOL isRead = true;
    while (isRead) {
        // Check if buffer is the same one
        if (memcmp(buffer, array, sizeof(buffer))) {
            isRead = false;
            return YES;
        }
        // ABCDEF -> BCDEFF
        [self shiftLeftArra:buffer num:sizeof(buffer)];
        // Read 1 byte into last buffer item
        if ([self readData:inputStream toBuffer:buffer + (sizeof(buffer) - 1) offset:0 maxLength:1] != 1) {
            isRead = false;
            return NO; // EOF
        }
    }
    return NO;
}

- (nullable NSString *)readLine:(nonnull NSInputStream *)inputStream {
    uint8_t bufferLine[MAX_LINE_SIZE];
    NSInteger offset = 0;
    NSInteger readBytes = 0;
    
    BOOL isLoop = YES;
    while (isLoop) {
        if (offset >= MAX_LINE_SIZE) {
            @throw [NSException exceptionWithName:@"NoResponseHeadersException" reason:@"" userInfo:nil];
        }

        readBytes = [inputStream read:bufferLine + offset maxLength:1];
        if (readBytes == 1) {
            if (offset > 0 && bufferLine[offset] == '\n') {
                if (offset == 1) {
                    isLoop = NO;
                    return @"";
                }
                isLoop = NO;
                return [[NSString alloc] initWithBytes:bufferLine length:offset - 1 encoding:NSUTF8StringEncoding];
            } else {
                offset++;
            }
        }
        
        if (readBytes <= 0) {
            isLoop = NO;
            return nil;
        }
    }
    return nil;
}

- (NSInteger)readData:(nonnull NSInputStream *)inputStream toBuffer:(nonnull uint8_t *)buffer offset:(NSInteger)offset maxLength:(NSInteger)length {
    // NSLog(@"readData(offset=%ld, length=%ld)", (long)offset, (long)length);
    NSInteger totalReadBytes = 0;
    NSInteger readBytes = 0;
    do {
        readBytes = [inputStream read:buffer + offset + totalReadBytes maxLength:length - totalReadBytes];
        
        if (readBytes > 0) {
            totalReadBytes += readBytes;
        }
    } while (readBytes >= 0 && totalReadBytes < length);

    return totalReadBytes;
}

- (void)dumpHeaders:(nonnull NSArray<NSDictionary<NSString *, NSString *> *> *)headers {
    for (NSDictionary<NSString *, NSString *> *head in headers) {
        NSString *key = head.allKeys.firstObject;
        NSString *value = head.allValues.firstObject;
        // NSLog(@"%@: %@", key, value);
    }
}

- (nullable NSString *)getHeader:(nonnull NSArray<NSDictionary<NSString *, NSString *> *> *)headers header:(nonnull NSString *)header {
    for (NSDictionary<NSString *, NSString *> *head in headers) {
        NSString *key = head.allKeys.firstObject;
        if ([header.lowercaseString isEqualToString:key.lowercaseString]) {
            return head[key];
        }
    }
    return nil;
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            break;
        case NSStreamEventHasBytesAvailable:
//            if (self.state == RTSPStatePlay) {
//                // NSLog(@"dataaaaaaaaaaaa");
//            }
            break;
        case NSStreamEventEndEncountered:
            break;
        case NSStreamEventErrorOccurred:
            break;
        default:
            break;
    }
}

- (void)RTSPCapturerDecodeDelegateSampleBuffer:(CMSampleBufferRef) samplebuffer {
    [self.delegate2 RTSPCapturerDecodeDelegateSampleBuffer:samplebuffer];
}

@end

@implementation VideoRtpParser

- (instancetype)init {
    self = [super init];
    if (self) {
        _buffer = (uint8_t *)calloc(1024, sizeof(uint8_t *));
        _nalEndFlag = NO;
        _bufferLength = 0;
        _packetNum = 0;
    }
    return self;
}

- (void)dealloc {
    free(_buffer);
}

- (nullable NSData *)processRtpPacketAndGetNalUnit:(nonnull uint8_t *)data length:(int)length {
    if (DEBUG) {
        // NSLog(@"%@: processRtpPacketAndGetNalUnit(length=%d)", TAG, length);
    }
    int tmpLen;
    int nalType = data[0] & 0x1F;
    int packFlag = data[1] & 0xC0;
    if (DEBUG) {
        // NSLog(@"%@: NAL type: %d, pack flag: %d", TAG, nalType, packFlag);
    }
    switch (nalType) {
        case NAL_UNIT_TYPE_STAP_A:
        case NAL_UNIT_TYPE_STAP_B:
        case NAL_UNIT_TYPE_MTAP16:
        case NAL_UNIT_TYPE_MTAP24:
        case NAL_UNIT_TYPE_FU_B:
            break;
        case NAL_UNIT_TYPE_FU_A:
            switch (packFlag) {
                    //NAL Unit start packet
                case 0x80: {
                    _nalEndFlag = false;
                    _packetNum = 1;
                    
                    uint8_t nalHeader = (data[0] & 0xE0) | (data[1] & 0x1F);
                    _nalUnit.push_back(nalHeader);
                    self.bufferLength = length - 1;
                    _nalUnit.insert(_nalUnit.end(), data + 2, data + length - 2);
                    break;
                }
                    //NAL Unit middle packet
                case 0x00: {
                    _nalEndFlag = false;
                    _packetNum++;
                    _bufferLength += length - 2;
                    _nalUnit.insert(_nalUnit.end(), data + 2, data + length - 2);
                    break;
                }
                    //NAL Unit end packet
                case 0x40: {
                    _nalEndFlag = true;
                    uint8_t prefix[] = {0x00, 0x00, 0x00, 0x01};
                    _bufferLength += length + 2;
                    _nalUnit.insert(_nalUnit.begin(), std::begin(prefix), std::end(prefix));
                    _nalUnit.insert(_nalUnit.end(), data + 2, data + length - 2);
                    break;
                }
            }
            break;
        default:
            NSLog(@"%@: Single NAL", TAG);
            _nalEndFlag = YES;
            _nalUnit.clear();
            uint8_t prefix[] = {0x00, 0x00, 0x00, 0x01};
            _nalUnit.insert(_nalUnit.begin(), std::begin(prefix), std::end(prefix));
            _nalUnit.insert(_nalUnit.end(), data, data + length);
            _bufferLength += length + 4;
            break;
    }
    if (self.nalEndFlag) {
        // NSLog(@"%@: NalSize: %lu", TAG, self.nalUnit.size());
        return [NSData dataWithBytes:_nalUnit.data() length:_bufferLength];
    } else {
        return nil;
    }
}

@end

@implementation RtpHeader

+ (BOOL)searchForNextRtpHeader:(NSInputStream *)inputStream header:(uint8_t *)header {
    if (sizeof(header) < 4) {
        // NSLog(@"Invalid allocated buffer size");
        return NO;
    }

    int bytesRemaining = 100000; // 100 KB max to check
    BOOL foundFirstByte = NO;
    BOOL foundSecondByte = NO;
    uint8_t oneByte[1];
    
    do {
        if (bytesRemaining-- < 0) {
            return NO;
        }
        // Read 1 byte
        if ([inputStream read:oneByte maxLength:1] <= 0) {
            return NO;
        }
        if (foundFirstByte) {
            if (oneByte[0] == 0x00) {
                foundSecondByte = YES;
            } else {
                foundFirstByte = NO;
            }
        }
        if (!foundFirstByte && oneByte[0] == 0x24) {
            foundFirstByte = YES;
        }
    } while (!foundSecondByte);
    
    header[0] = 0x24;
    header[1] = oneByte[0];
    // Read 2 bytes more (packet size)
    if ([inputStream read:header + 2 maxLength:2] != 2) {
        return NO;
    }
    return YES;
}

+ (nullable RtpHeader *)parseData:(uint8_t *)header packetSize:(int)packetSize {
    RtpHeader *rtpHeader = [[RtpHeader alloc] init];
    rtpHeader.version = (header[0] & 0xFF) >> 6;
    if (rtpHeader.version != 2) {
        if (DEBUG) {
            // NSLog(@"Not a RTP packet (%d)", rtpHeader.version);
        }
        return nil;
    }

    rtpHeader.padding = (header[0] & 0x20) >> 5;
    rtpHeader.extension = (header[0] & 0x10) >> 4;
    rtpHeader.marker = (header[1] & 0x80) >> 7;
    rtpHeader.payloadType = header[1] & 0x7F;
    rtpHeader.sequenceNumber = (header[3] & 0xFF) + ((header[2] & 0xFF) << 8);
    rtpHeader.timeStamp = (header[7] & 0xFF) + ((header[6] & 0xFF) << 8) + ((header[5] & 0xFF) << 16) + ((header[4] & 0xFF) << 24) & 0xffffffffL;
    rtpHeader.ssrc = (header[7] & 0xFF) + ((header[6] & 0xFF) << 8) + ((header[5] & 0xFF) << 16) + ((header[4] & 0xFF) << 24) & 0xffffffffL;
    rtpHeader.payloadSize = packetSize - RTP_HEADER_SIZE;
    
    // NSLog(@"RTP header version: %d, padding: %d, ext: %d, cc: %d, marker: %d, payload type: %d, seq num: %d, ts: %ld, ssrc: %ld, payload size: %d",
//          rtpHeader.version, rtpHeader.padding, rtpHeader.extension, rtpHeader.cc, rtpHeader.marker, rtpHeader.payloadType, rtpHeader.sequenceNumber, rtpHeader.timeStamp, rtpHeader.ssrc, rtpHeader.payloadSize);

    return rtpHeader;
}

+ (int)getPacketSize:(uint8_t *)header {
    int packetSize = ((header[2] & 0xFF) << 8) | (header[3] & 0xFF);
    // NSLog(@"Packet size: %d", packetSize);
    return packetSize;
}

@end

