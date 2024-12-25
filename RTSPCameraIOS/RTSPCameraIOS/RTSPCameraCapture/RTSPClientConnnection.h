//
//  RTSPClientConnection.h
//  live555-simple-demo-4-iOS
//
//  Created by Mac Mini 2021_1 on 4/7/24.
//  Copyright © 2024 TheFlyingPenguin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <vector>
#include "RTSPCapturerDecode.h"

static NSString *const TAG = @"RtspClient";
static NSString *const TAG_DEBUG = @"RtspClient DBG";

typedef NS_ENUM(NSInteger, RTSPState) {
    RTSPStateOptions,
    RTSPStateDescribe,
    RTSPStateSetup,
    RTSPStatePlay
};

typedef NS_OPTIONS(NSUInteger, RTSPCapability) {
    RTSPCapabilityNone          = 0,
    RTSPCapabilityOptions       = 1 << 1,
    RTSPCapabilityDescribe      = 1 << 2,
    RTSPCapabilityAnnounce      = 1 << 3,
    RTSPCapabilitySetup         = 1 << 4,
    RTSPCapabilityPlay          = 1 << 5,
    RTSPCapabilityRecord        = 1 << 6,
    RTSPCapabilityPause         = 1 << 7,
    RTSPCapabilityTeardown      = 1 << 8,
    RTSPCapabilitySetParameter  = 1 << 9,
    RTSPCapabilityGetParameter  = 1 << 10,
    RTSPCapabilityRedirect      = 1 << 11
};

typedef NS_ENUM(NSUInteger, VideoCodec) {
    VideoCodecH264 = 0,
    VideoCodecH265 = 1
};

typedef NS_ENUM(NSInteger, AudioCodecType) {
    AudioCodecUnknown = -1,
    AudioCodecAAC = 0,
    AudioCodecOpus = 1
};

// Define constants
static const int NAL_UNIT_TYPE_STAP_A = 24;
static const int NAL_UNIT_TYPE_STAP_B = 25;
static const int NAL_UNIT_TYPE_MTAP16 = 26;
static const int NAL_UNIT_TYPE_MTAP24 = 27;
static const int NAL_UNIT_TYPE_FU_A = 28;
static const int NAL_UNIT_TYPE_FU_B = 29;

@interface Track: NSObject
@property (nonatomic, copy, nullable) NSString * request;
@property (nonatomic) int payloadType;
@end

@interface VideoTrack : Track
@property (nonatomic) VideoCodec videoCodec;
@property (nonatomic, copy, nullable) NSData *sps;
@property (nonatomic, copy, nullable) NSData *pps;

- (instancetype _Nonnull) initWithCodec:(VideoCodec) codec;
@end

@interface AudioTrack : Track
@property (nonatomic) AudioCodecType audioCodec;
@property (nonatomic) int sampleRateHz;
@property (nonatomic) int channels;
@property (nonatomic, nullable) NSString *mode;
@property (nonatomic, nullable) NSData *config;

- (instancetype _Nonnull) initWithCodec:(AudioCodecType) codec;
@end

//@interface SdpInfo : NSObject
//@property (nonatomic, nullable) NSString *sessionName;
//@property (nonatomic, nullable) NSString *sessionDescription;
//@property (nonatomic, copy, nullable) VideoTrack* videoTrack;
//@property (nonatomic, copy, nullable) AudioTrack* audioTrack;
//
//- (instancetype _Nullable) initWithVideoTrack:(VideoTrack* _Nullable) videoTrack audioTrack:(AudioTrack* _Nullable) audioTrack;
//-(instancetype _Nullable) initWithSession:(NSString* _Nonnull) session description:(NSString* _Nonnull) description;
//
//@end

typedef struct {
    __unsafe_unretained NSString * _Nullable sessionName;
    __unsafe_unretained NSString * _Nullable sessionDescription;
    __unsafe_unretained VideoTrack * _Nullable videoTrack;
    __unsafe_unretained AudioTrack * _Nullable audioTrack;
} SdpInfo;

static int RTP_HEADER_SIZE = 12;

@protocol RTSPClientConnnectionDelegate <NSObject>
- (void)onRtspConnecting;
- (void)onRtspConnected:(SdpInfo)sdpInfo;
- (void)onRtspVideoBufferReceived:(CMSampleBufferRef _Nullable)samplebuffer;
- (void)onRtspVideoNalUnitReceived:(NSData * _Nullable)data offset:(NSInteger)offset length:(NSInteger)length timestamp:(int64_t)timestamp;
- (void)onRtspAudioSampleReceived:(NSData * _Nullable)data offset:(NSInteger)offset length:(NSInteger)length timestamp:(int64_t)timestamp;
- (void)onRtspDisconnecting;
- (void)onRtspDisconnected;
- (void)onRtspFailedUnauthorized;
- (void)onRtspFailed:(NSString * _Nullable)message;
@end

@protocol RTSPClientConnnectionDelegate2 <NSObject>
- (void)RTSPCapturerDecodeDelegateSampleBuffer:(CMSampleBufferRef _Nullable) samplebuffer;
@end

@interface RTSPClientConnnection: NSObject<NSStreamDelegate, RTSPCapturerDecodeDelegate>

@property (weak, nonatomic) id<RTSPClientConnnectionDelegate> _Nullable delegate;
@property (weak, nonatomic) id<RTSPClientConnnectionDelegate2> _Nullable delegate2;
@property (nonatomic, strong) NSInputStream * _Nonnull inputStream;
@property (nonatomic, strong) NSOutputStream * _Nonnull outputStream;
@property (nonatomic, strong) dispatch_queue_t networkQueue;
@property (nonatomic, strong) NSThread *decodeThread;
@property (nonatomic) RTSPState state;
@property (nonatomic) RTSPCapturerDecode * _Nonnull decoder;

- (instancetype _Nullable) initWithUrl:(NSString* _Nonnull) url;

- (void) startVideo;
- (void) startWithUsername:(NSString* _Nonnull) username
                  password:(NSString* _Nonnull) password
              requestVideo:(BOOL) isVideo
              requestAudio:(BOOL) isAudio;
- (void) startVideoWithUsername:(NSString* _Nonnull) username
                       password:(NSString* _Nonnull) password;

@end

@interface VideoRtpParser : NSObject
@property (nonatomic, assign, nullable) uint8_t * buffer;
@property (nonatomic, assign) std::vector<uint8_t> nalUnit;
@property (nonatomic, assign) BOOL nalEndFlag;
@property (nonatomic, assign) int bufferLength;
@property (nonatomic, assign) int packetNum;
- (nullable NSData *)processRtpPacketAndGetNalUnit:(nonnull uint8_t *)data length:(int)length;
@end

#import <Foundation/Foundation.h>

@interface RtpHeader : NSObject

@property (nonatomic, assign) int version;
@property (nonatomic, assign) int padding;
@property (nonatomic, assign) int extension;
@property (nonatomic, assign) int cc;
@property (nonatomic, assign) int marker;
@property (nonatomic, assign) int payloadType;
@property (nonatomic, assign) int sequenceNumber;
@property (nonatomic, assign) long timeStamp;
@property (nonatomic, assign) long ssrc;
@property (nonatomic, assign) int payloadSize;

+ (BOOL)searchForNextRtpHeader:(NSInputStream * _Nullable)inputStream header:(uint8_t *_Nullable)header;
+ (nullable RtpHeader *)parseData:(uint8_t * _Nullable)header packetSize:(int)packetSize;
+ (int)getPacketSize:(uint8_t * _Nullable)header;

@end
