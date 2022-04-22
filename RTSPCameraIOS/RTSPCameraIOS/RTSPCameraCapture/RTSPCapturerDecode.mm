//
//  RTSPCapturerDecode.m
//  RTSPCameraIOS
//
//  Created by Mac Mini 2021_1 on 21/04/2022.
//

#import <Foundation/Foundation.h>
#import "RTSPCapturerDecode.h"

bool H264AnnexBBufferHasVideoFormatDescription(uint8_t* annexb_buffer,
                                               size_t annexb_buffer_size) {
    
  uint8_t first_nalu_type = annexb_buffer[4] & 0x0F;
  bool is_first_nalu_type_sps = first_nalu_type == 7;
  if (is_first_nalu_type_sps)
    return true;
  bool is_first_nalu_type_aud = first_nalu_type == 9;
  // Start code + access unit delimiter + start code = 4 + 2 + 4 = 10.
  if (!is_first_nalu_type_aud || annexb_buffer_size <= 10u)
    return false;
  uint8_t second_nalu_type = annexb_buffer[10] & 0x0F;
  bool is_second_nalu_type_sps = second_nalu_type == 7;
  return is_second_nalu_type_sps;
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
   }
}

@implementation RTSPCapturerDecode

- (void)createDecoder {
//    [self createDecompSession];
}

- (void)decode:(FrameEncoded*) encodedImage {
    
    uint8_t* frame = encodedImage->buffer();
    bool a = H264AnnexBBufferHasVideoFormatDescription(encodedImage->buffer(), encodedImage->size());
    for (int i = 0 ; i < (uint32_t)encodedImage->size(); i++)
    {
        NSLog(@"Thien buffer %d", (int)frame[i]);
    }
    NSLog(@"Thien buffer 111111: %d",a);
    [self receivedRawVideoFrame:encodedImage->buffer() withSize:(uint32_t)encodedImage->size()];
}

-(void) receivedRawVideoFrame:(uint8_t *)frame withSize:(uint32_t)frameSize
{
   OSStatus status;

   uint8_t *data = NULL;
   uint8_t *pps = NULL;
   uint8_t *sps = NULL;

   // I know how my H.264 data source's NALUs looks like so I know start code index is always 0.
   // if you don't know where it starts, you can use a for loop similar to how I find the 2nd and 3rd start codes
   int startCodeIndex = 0;
   int secondStartCodeIndex = 0;
   int thirdStartCodeIndex = 0;

   long blockLength = 0;

   CMSampleBufferRef sampleBuffer = NULL;
   CMBlockBufferRef blockBuffer = NULL;

   int nalu_type = (frame[4] & 0x1F);
   NSLog(@"~~~~~~~ Received NALU Type \"%@\" ~~~~~~~~", naluTypesStrings[nalu_type]);

   // if we havent already set up our format description with our SPS PPS parameters, we
   // can't process any frames except type 7 that has our parameters
   if (nalu_type != 7 && _formatDesc == NULL)
   {
       NSLog(@"Video error: Frame is not an I Frame and format description is null");
       return;
   }

   // NALU type 7 is the SPS parameter NALU
   if (nalu_type == 7)
   {
       // find where the second PPS start code begins, (the 0x00 00 00 01 code)
       // from which we also get the length of the first SPS code
       for (int i = startCodeIndex + 4 ; i < frameSize; i++)
       {
           if (frame[i] == 0x00 && frame[i+1] == 0x00 && frame[i+2] == 0x00 && frame[i+3] == 0x01)
           {
               secondStartCodeIndex = i;
               _spsSize = secondStartCodeIndex;   // includes the header in the size
               break;
           }
       }
//
//       // find what the second NALU type is
       nalu_type = (frame[secondStartCodeIndex + 4] & 0x1F);
       NSLog(@"~~~~~~~ Received NALU Type \"%@\" ~~~~~~~~", naluTypesStrings[nalu_type]);
   }


   // type 8 is the PPS parameter NALU
//   if(nalu_type == 8) {
//
//       // find where the NALU after this one starts so we know how long the PPS parameter is
//       for (int i = _spsSize + 12; i < _spsSize + 50; i++)
//       {
//           if (frame[i] == 0x00 && frame[i+1] == 0x00 && frame[i+2] == 0x00 && frame[i+3] == 0x01)
//           {
//               thirdStartCodeIndex = i;
//               _ppsSize = thirdStartCodeIndex - _spsSize;
//               break;
//           }
//       }
//
//       // allocate enough data to fit the SPS and PPS parameters into our data objects.
//       // VTD doesn't want you to include the start code header (4 bytes long) so we add the - 4 here
//       sps = (uint8_t *)malloc(_spsSize - 4);
//       pps = (uint8_t *)malloc(_ppsSize - 4);
//
//       // copy in the actual sps and pps values, again ignoring the 4 byte header
//       memcpy (sps, &frame[4], _spsSize-4);
//       memcpy (pps, &frame[_spsSize+4], _ppsSize-4);
//
//       // now we set our H264 parameters
//       uint8_t*  parameterSetPointers[2] = {sps, pps};
//       size_t parameterSetSizes[2] = {static_cast<size_t>(_spsSize-4), static_cast<size_t>(_ppsSize-4)};
//
//       status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2,
//                                                                    (const uint8_t *const*)parameterSetPointers,
//                                                                    parameterSetSizes, 4,
//                                                                    &_formatDesc);
//
//       NSLog(@"\t\t Creation of CMVideoFormatDescription: %@", (status == noErr) ? @"successful!" : @"failed...");
//       if(status != noErr) NSLog(@"\t\t Format Description ERROR type: %d", (int)status);
//
//       // See if decomp session can convert from previous format description
//       // to the new one, if not we need to remake the decomp session.
//       // This snippet was not necessary for my applications but it could be for yours
//       /*BOOL needNewDecompSession = (VTDecompressionSessionCanAcceptFormatDescription(_decompressionSession, _formatDesc) == NO);
//        if(needNewDecompSession)
//        {
//        [self createDecompSession];
//        }*/
//
//       // now lets handle the IDR frame that (should) come after the parameter sets
//       // I say "should" because that's how I expect my H264 stream to work, YMMV
//       nalu_type = (frame[thirdStartCodeIndex + 4] & 0x1F);
//       NSLog(@"~~~~~~~ Received NALU Type \"%@\" ~~~~~~~~", naluTypesStrings[nalu_type]);
//   }

   // create our VTDecompressionSession.  This isnt neccessary if you choose to use AVSampleBufferDisplayLayer
   if((status == noErr) && (_decompressionSession == NULL))
   {
       [self createDecompSession];
   }

   // type 5 is an IDR frame NALU.  The SPS and PPS NALUs should always be followed by an IDR (or IFrame) NALU, as far as I know
   if(nalu_type == 5)
   {
       // find the offset, or where the SPS and PPS NALUs end and the IDR frame NALU begins
       int offset = _spsSize + _ppsSize;
       blockLength = frameSize - offset;
       //        NSLog(@"Block Length : %ld", blockLength);
       data = (uint8_t*)malloc(blockLength);
       data = (uint8_t*)memcpy(data, &frame[offset], blockLength);

       // replace the start code header on this NALU with its size.
       // AVCC format requires that you do this.
       // htonl converts the unsigned int from host to network byte order
       uint32_t dataLength32 = htonl (blockLength - 4);
       memcpy (data, &dataLength32, sizeof (uint32_t));

       // create a block buffer from the IDR NALU
       status = CMBlockBufferCreateWithMemoryBlock(NULL, data,  // memoryBlock to hold buffered data
                                                   blockLength,  // block length of the mem block in bytes.
                                                   kCFAllocatorNull, NULL,
                                                   0, // offsetToData
                                                   blockLength,   // dataLength of relevant bytes, starting at offsetToData
                                                   0, &blockBuffer);

       NSLog(@"\t\t BlockBufferCreation: \t %@", (status == kCMBlockBufferNoErr) ? @"successful!" : @"failed...");
   }

   // NALU type 1 is non-IDR (or PFrame) picture
   if (nalu_type == 1)
   {
       // non-IDR frames do not have an offset due to SPS and PSS, so the approach
       // is similar to the IDR frames just without the offset
       blockLength = frameSize;
       data = (uint8_t*)malloc(blockLength);
       data = (uint8_t*)memcpy(data, &frame[0], blockLength);

       // again, replace the start header with the size of the NALU
       uint32_t dataLength32 = htonl (blockLength - 4);
       memcpy (data, &dataLength32, sizeof (uint32_t));

       status = CMBlockBufferCreateWithMemoryBlock(NULL, data,  // memoryBlock to hold data. If NULL, block will be alloc when needed
                                                   blockLength,  // overall length of the mem block in bytes
                                                   kCFAllocatorNull, NULL,
                                                   0,     // offsetToData
                                                   blockLength,  // dataLength of relevant data bytes, starting at offsetToData
                                                   0, &blockBuffer);

       NSLog(@"\t\t BlockBufferCreation: \t %@", (status == kCMBlockBufferNoErr) ? @"successful!" : @"failed...");
   }

   // now create our sample buffer from the block buffer,
   if(status == noErr)
   {
       // here I'm not bothering with any timing specifics since in my case we displayed all frames immediately
       const size_t sampleSize = blockLength;
       status = CMSampleBufferCreate(kCFAllocatorDefault,
                                     blockBuffer, true, NULL, NULL,
                                     _formatDesc, 1, 0, NULL, 1,
                                     &sampleSize, &sampleBuffer);

       NSLog(@"\t\t SampleBufferCreate: \t %@", (status == noErr) ? @"successful!" : @"failed...");
   }

   if(status == noErr)
   {
       // set some values of the sample buffer's attachments
       CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
       CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
       CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);

       // either send the samplebuffer to a VTDecompressionSession or to an AVSampleBufferDisplayLayer
       [self render:sampleBuffer];
   }

   // free memory to avoid a memory leak, do the same for sps, pps and blockbuffer
   if (NULL != data)
   {
       free (data);
       data = NULL;
   }
}

-(void) createDecompSession {
   // make sure to destroy the old VTD session
   _decompressionSession = NULL;
   VTDecompressionOutputCallbackRecord callBackRecord;
   callBackRecord.decompressionOutputCallback = decompressionSessionDecodeFrameCallback;

   // this is necessary if you need to make calls to Objective C "self" from within in the callback method.
   callBackRecord.decompressionOutputRefCon = (__bridge void *)self;

   // you can set some desired attributes for the destination pixel buffer.  I didn't use this but you may
   // if you need to set some attributes, be sure to uncomment the dictionary in VTDecompressionSessionCreate
//   NSDictionary *destinationImageBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
//    [NSNumber numberWithBool:YES],
//    (id)kCVPixelBufferOpenGLESCompatibilityKey,
//    nil];

   OSStatus status =  VTDecompressionSessionCreate(
                                                   nullptr, _formatDesc, nullptr,
                                                   nullptr,
//                                                   (__bridge CFDictionaryRef)(destinationImageBufferAttributes),
                                                   &callBackRecord, &_decompressionSession);
   NSLog(@"Video Decompression Session Create: \t %@", (status == noErr) ? @"successful!" : @"failed...");
   if(status != noErr) NSLog(@"\t\t VTD ERROR type: %d", (int)status);
}

- (void)createFormatDescription:(uint8_t*) sps ppsData:(uint8_t*) pps andsizeSps:(size_t)sps_size andpps:(size_t)pps_size {
    
    const uint8_t *props[] = {sps + 4, pps + 4};
    size_t sizes[] = {sps_size - 12, pps_size - 4};

    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(NULL, 2, props, sizes, 4, &_formatDesc);
    NSLog(@"\t\t BlockBufferCreation: \t %@", (status == kCMBlockBufferNoErr) ? @"successful!" : @"failed...");
//    [self createDecompSession];
}

- (void) render:(CMSampleBufferRef)sampleBuffer
{
   /*
    VTDecodeFrameFlags flags = kVTDecodeFrame_EnableAsynchronousDecompression;
    VTDecodeInfoFlags flagOut;
    NSDate* currentTime = [NSDate date];
    VTDecompressionSessionDecodeFrame(_decompressionSession, sampleBuffer, flags,
    (void*)CFBridgingRetain(currentTime), &flagOut);
   
    CFRelease(sampleBuffer);*/
    NSLog(@"Success ****");
   // if you're using AVSampleBufferDisplayLayer, you only need to use this line of code
   if (_videoLayer) {
       
       [_videoLayer enqueueSampleBuffer:sampleBuffer];
   }
  
}
@end

