//
//  RTSPCapturerDecode.m
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 21/04/2022.
//

#import <Foundation/Foundation.h>
#import "RTSPCapturerDecode.h"

struct RTSPFrameDecodeParams {
    RTSPFrameDecodeParams(int64_t ts, CMVideoFormatDescriptionRef format) :timestamp(ts), format(format) {
        //
    }
    int64_t timestamp;
    CMVideoFormatDescriptionRef format;
    uint64_t pts;
};

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
       NSLog(@"seconds = %f", CMTimeGetSeconds(presentationTimeStamp));
       NSLog(@"Decompressed sucessfully");
       std::unique_ptr<RTSPFrameDecodeParams> decoded_params(
           reinterpret_cast<RTSPFrameDecodeParams *>(sourceFrameRefCon));
       CMSampleBufferRef samplebuffer ;
       CMSampleTimingInfo time = CMSampleTimingInfo();
       CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault, imageBuffer, decoded_params->format, &time, &samplebuffer);
       
   }
}

@implementation RTSPCapturerDecode

- (instancetype)init {
  if (self = [super init]) {
      pts_counter_ = 0;
      _formatDesc = NULL;
  }
  return self;
}

- (void)decode:(FrameEncoded*) encodedImage {
    presentation_time_ = encodedImage->presentation_time();
    [self receivedRawVideoFrame:encodedImage->buffer() withSize:(uint32_t)encodedImage->size()];
}

-(void) receivedRawVideoFrame:(uint8_t *)frame withSize:(uint32_t)frameSize
{
    uint64_t presentation_time_ = self->presentation_time_;
    if(presentation_time_ == 0){
      presentation_time_ = pts_counter_;
    }
    pts_counter_ = presentation_time_ + 1;
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
//    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DoNotDisplay, kCFBooleanFalse);
    
    [self render:sampleBuffer];
    
    VTDecodeFrameFlags decodeFlags = kVTDecodeFrame_EnableAsynchronousDecompression;
    std::unique_ptr<RTSPFrameDecodeParams> frameDecodeParams;
    frameDecodeParams.reset(new RTSPFrameDecodeParams(presentation_time_, _formatDesc));
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

@end
