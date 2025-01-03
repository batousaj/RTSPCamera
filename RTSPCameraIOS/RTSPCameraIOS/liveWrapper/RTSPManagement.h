//
//  RTSPManagement.hpp
//  live555helper
//
//  Created by Mac Mini 2021_1 on 18/04/2022.
//


#pragma once
#include <stdio.h>
#include <string.h>
#include <map>
#include <queue>
#include <thread>

#include "FrameEncoded.h"
#include "environment.h"
#include "rtspconnectionclient.h"

class RTSPSourceFactory;
typedef RTSPSourceFactory* (*CreatePointerFuncFactory)(void);

class RTSPControl {
public :
    virtual void startRTSP() = 0;
    virtual void stopRTSP() = 0;
};

class RTSPSourceFactory {
public :
    virtual void registerRTSPControl(RTSPControl* controller) = 0;
    virtual void onDecodeParams(FrameEncoded* sps, FrameEncoded* pps) = 0;
    virtual void onData(FrameEncoded* frame, bool isReset) = 0;
    static void SetRTSPSourceFactory(CreatePointerFuncFactory create_func);
    virtual void receivedRawVideoFrame(uint8_t * frame, uint32_t frameSize, struct timeval presentationTime) = 0;
    static RTSPSourceFactory* Create();
};

class RTSPManagement : public RTSPControl,
                       public RTSPConnection::Callback {
public :
    RTSPManagement(const std::string &uri, const std::map<std::string,std::string> &opts);
                           
    //Start/Stop session of RTSPVideoCapturer
    void startRTSP() override;
    void stopRTSP() override;
                           
    virtual ~RTSPManagement();

    static RTSPManagement* Create(std::string &uri, const std::map<std::string,std::string> &opts) {
         return new RTSPManagement(uri,opts);
    };
                               
    //Thread in decode RTSPVideo
    void CapturerThread() ;
                           
    //override RTSPConnection:Callback
    virtual void onError(RTSPConnection& connection , const char* error) override;

    void onConnectionTimeout(RTSPConnection& connection) override {
        connection.start();
    }

    void onDataTimeout(RTSPConnection& connection) override {
        connection.start();
    }

    virtual bool onNewSession(const char* id, const char* media, const char* codec, const char* sdp) override;

    virtual bool onData(const char* id, unsigned char* buffer, ssize_t size, struct timeval presentationTime) override;
                           
    private :
         uint64_t getPresentationTime(struct timeval presentationTime);
                           
         void consumeFramesAndDecode();
            
         void CheckCodecType(const char* codec) {
            if (strcmp(codec, "H264") == 0) {
                m_codec = common::kCodecH264;
            }  else if (strcmp(codec, "H265") == 0) {
                m_codec = common::kCodecH265;
            } else if (strcmp(codec, "VP9") == 0) {
                m_codec = common::kCodecVP9;
            } else if (strcmp(codec, "HEVC") == 0) {
                m_codec = common::kCodecHEVC;
            } else if (strcmp(codec, "JPEG") == 0) {
                m_codec = common::kCodecJPEG;
            }
         }
                           
                           struct FramQueue {
                               FramQueue(std::vector<uint8_t> data, timeval presentationTime1) {
                                   frame = data;
                                   presentationTime = presentationTime1;
                               }
                               
                               std::vector<uint8_t> frame;
                               timeval presentationTime;
                           };
                           
    private :
        //environment process thread manager
        Environment m_envi;
        char        m_stop;
        std::thread m_thread;
        std::thread consumerThread;
        std::vector<uint8_t> m_cfg;
        //RTSPConnection
        RTSPConnection m_connection;
        common::CodecType m_codec;
        RTSPSourceFactory* source_factory;
        bool         isResetDescription;
                           std::queue<FramQueue> frameQueue;
                           std::mutex queueMutex;
                           std::condition_variable queueCondition;
};
