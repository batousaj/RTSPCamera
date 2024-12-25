//
//  RTSPCapturerDecode.m
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 21/04/2022.
//

#import <Foundation/Foundation.h>
#import "RTSPCapturerDecode.h"

struct RTSPFrameDecodeParams {
    RTSPFrameDecodeParams(id<RTSPCapturerDecodeDelegate> callback, int64_t ts, CMVideoFormatDescriptionRef format) : callback(callback), timestamp(ts), format(format) {
//    } bufferStored(bufferStored) {
        //
    }
    
    id<RTSPCapturerDecodeDelegate> callback;
    int64_t timestamp;
    CMVideoFormatDescriptionRef format;
    uint64_t pts;
//    StoredBuffer *bufferStored;
};

void storedDataFrame(uint8_t* frame,
                     uint32_t presentation_time) {
    
}

void decompressionSessionDecodeFrameCallback(void *decompressionOutputRefCon,
                                            void *sourceFrameRefCon,
                                            OSStatus status,
                                            VTDecodeInfoFlags infoFlags,
                                            CVImageBufferRef imageBuffer,
                                            CMTime presentationTimeStamp,
                                            CMTime presentationDuration)
{
  
   if (status != noErr)
   {
       NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
       NSLog(@"Decompressed error: %@", error);
   }
   else
   {
       NSLog(@"Decompressed sucessfully");
       std::unique_ptr<RTSPFrameDecodeParams> decoded_params(
           reinterpret_cast<RTSPFrameDecodeParams *>(sourceFrameRefCon));
       CMSampleBufferRef samplebuffer ;
//       CMSampleTimingInfo time = CMSampleTimingInfo();
       CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
       timing.presentationTimeStamp = CMTimeMake(decoded_params->timestamp, 1000000000);
       OSStatus status = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, imageBuffer, YES, NULL, NULL, decoded_params->format, &timing, &samplebuffer);
       if (status != noErr)
       {
           NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
           NSLog(@"samplebuffer error: %@", error);
       }
       [decoded_params->callback RTSPCapturerDecodeDelegateSampleBuffer:samplebuffer];
   }
}

@implementation RTSPCapturerDecode

- (instancetype)init {
  if (self = [super init]) {
      pts_counter_ = 0;
      _formatDesc = NULL;
//      stored_data.clear();
      self.pts_time_ = [[NSMutableArray alloc] initWithCapacity:0];
      self.buffer = [[NSMutableArray alloc] initWithCapacity:0];
  }
  return self;
}

- (void)decode:(FrameEncoded*) encodedImage andReset:(BOOL)isReset {
    presentation_time_ = encodedImage->presentation_time();
    NSData *buffer = [NSData dataWithBytes:encodedImage->buffer() length:encodedImage->size()];
//    if (isReset) {
        [self receivedRawVideoFrame:(uint8_t*)encodedImage->buffer() withSize:(uint32_t)encodedImage->size()];
//    } else {
//        [self sortingByte:buffer andTime:(int)presentation_time_];
//        if ([self isPlayBuffer]) {
//            NSData* data = [self getBufferPlay];
//            [self.buffer removeObjectAtIndex:0];
//            [self.pts_time_ removeObjectAtIndex:0];
//            [self receivedRawVideoFrame:(uint8_t*)data.bytes withSize:(uint32_t)data.length];
//        }
//    }
}

-(void) receivedRawVideoFrame:(uint8_t *)frame withSize:(uint32_t)frameSize
{
    CMVideoFormatDescriptionRef inputFormat = nullptr;
    if (H264AnnexBBufferHasVideoFormatDescription((uint8_t *)frame,
                                                            frameSize)) {
      inputFormat = CreateVideoFormatDescription((uint8_t *)frame,
                                                            frameSize);
      if (inputFormat) {
        // Check if the video format has changed, and reinitialize decoder if
        // needed.
        if (!CMFormatDescriptionEqual(inputFormat, _formatDesc)) {
          [self setVideoFormat:inputFormat];
          [self createDecompSession];
        }
        CFRelease(inputFormat);
      }
    }
    if (!_formatDesc) {
      // We received a frame but we don't have format information so we can't
      // decode it.
      // This can happen after backgrounding. We need to wait for the next
      // sps/pps before we can resume so we request a keyframe by returning an
      // error.
      NSLog(@"Missing video format. Frame with sps/pps required.");
        return;
    }
    CMSampleBufferRef sampleBuffer = nullptr;
    if (!H264AnnexBBufferToCMSampleBuffer((uint8_t *)frame,
                                                    frameSize,
                                                    _formatDesc,
                                                    &sampleBuffer)) {
      return;
    }
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);

//    [self render:sampleBuffer];
    
    VTDecodeFrameFlags decodeFlags = kVTDecodeFrame_EnableAsynchronousDecompression;
    std::unique_ptr<RTSPFrameDecodeParams> frameDecodeParams;
    frameDecodeParams.reset(new RTSPFrameDecodeParams(self.delegate, presentation_time_, _formatDesc));
    OSStatus status = VTDecompressionSessionDecodeFrame(
        _decompressionSession, sampleBuffer, decodeFlags, frameDecodeParams.release(), nullptr);
    CFRelease(sampleBuffer);
    if (status != noErr) {
        NSLog(@"Failed to decode frame with code: %d",status);
        return ;
    }
    NSLog(@"Decode successful");
}

-(void) createDecompSession {
    _decompressionSession = NULL;

    static size_t const attributesSize = 3;
    CFTypeRef keys[attributesSize] = {
      kCVPixelBufferOpenGLESCompatibilityKey,
      kCVPixelBufferIOSurfacePropertiesKey,
      kCVPixelBufferPixelFormatTypeKey
    };
    CFDictionaryRef ioSurfaceValue = CreateCFTypeDictionary(nullptr, nullptr, 0);
    int64_t nv12type = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    CFNumberRef pixelFormat = CFNumberCreate(nullptr, kCFNumberLongType, &nv12type);
    CFTypeRef values[attributesSize] = {kCFBooleanTrue, ioSurfaceValue, pixelFormat};
    CFDictionaryRef attributes = CreateCFTypeDictionary(keys, values, attributesSize);
    if (ioSurfaceValue) {
      CFRelease(ioSurfaceValue);
      ioSurfaceValue = nullptr;
    }
    if (pixelFormat) {
      CFRelease(pixelFormat);
      pixelFormat = nullptr;
    }
    VTDecompressionOutputCallbackRecord record = {
        decompressionSessionDecodeFrameCallback, (__bridge void *)self,
    };
    OSStatus status = VTDecompressionSessionCreate(
        nullptr, _formatDesc, nullptr, attributes, &record, &_decompressionSession);
    CFRelease(attributes);
    if (status != noErr) {
        NSLog(@"Video Decompression Session Create: \t %@", (status == noErr) ? @"successful!" : @"failed...");
      [self destroyDecompressionSession];
    }
    [self configureDecompressionSession];
}

- (void)configureDecompressionSession {
  assert(_decompressionSession);
  VTSessionSetProperty(_decompressionSession, kVTDecompressionPropertyKey_RealTime, kCFBooleanTrue);
}

- (void)destroyDecompressionSession {
  if (_decompressionSession) {
    VTDecompressionSessionWaitForAsynchronousFrames(_decompressionSession);
    VTDecompressionSessionInvalidate(_decompressionSession);
    CFRelease(_decompressionSession);
    _decompressionSession = nullptr;
  }
}

- (void)setVideoFormat:(CMVideoFormatDescriptionRef)videoFormat {
  if (_formatDesc == videoFormat) {
    return;
  }
  if (_formatDesc) {
    CFRelease(_formatDesc);
  }
    _formatDesc = videoFormat;
  if (_formatDesc) {
    CFRetain(_formatDesc);
  }
}


- (void) render:(CMSampleBufferRef)sampleBuffer
{
    NSLog(@"presentation_time_: %llu",presentation_time_);
    [self.delegate RTSPCapturerDecodeDelegateSampleBuffer:sampleBuffer];
}

- (void) sortingByte:(NSData*)buffer andTime:(int)present_time_ {
    NSNumber *presentation_time = [NSNumber numberWithInt:(int)present_time_];
    if ([self.pts_time_ count] > 0) {
        NSNumber* largest_time_ = 0;
//        for (int i = 0; i < [self.pts_time_ count]; i++) {
//            if ( [largest_time_ intValue] <= [self.pts_time_[i] intValue]) {
//                NSLog(@"thien %d",i);
//                largest_time_ = self.pts_time_[i];
//            }
//        }
        largest_time_ = self.pts_time_[[self.pts_time_ count] - 1];
        
        if ([largest_time_ intValue] > [presentation_time intValue] && [presentation_time intValue] >= [self.pts_time_[0] intValue]) {
            for (int i = 0; i < [self.pts_time_ count]; i++) {
                if ( [[self.pts_time_ objectAtIndex:i] intValue] <= [presentation_time intValue] && [presentation_time intValue] <= [[self.pts_time_ objectAtIndex:i+1] intValue]) {
                    [self.pts_time_ insertObject:presentation_time atIndex: i+1];
                    [self.buffer insertObject:buffer atIndex:i+1];
                    break;
                }
            }
        } else if ([presentation_time intValue] < [self.pts_time_[0] intValue]) {
            [self.pts_time_ insertObject:presentation_time atIndex: 0];
            [self.buffer insertObject:buffer atIndex:0];
        } else {
            [self.pts_time_ addObject:presentation_time];
            [self.buffer addObject:buffer];
        }
    } else {
        [self.pts_time_ addObject:presentation_time];
        [self.buffer addObject:buffer];
    }
    
}

- (NSData*)getBufferPlay {
    NSData* data = [self.buffer objectAtIndex:0];
    return data;
}

- (BOOL)isPlayBuffer {
    if ([self.pts_time_ count] > 5) {
        return YES;
    }
    return NO;
}

@end
