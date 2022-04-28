//
//  RTSPManagement.cpp
//  live555helper
//
//  Created by Mac Mini 2021_1 on 18/04/2022.
//

#include <iostream>
#include "RTSPManagement.h"

//global variable
RTSPSourceFactory* NullPointerFunc(void) {
    return nullptr;
}

static CreatePointerFuncFactory rtsp_source_factory = NullPointerFunc;

void RTSPSourceFactory::SetRTSPSourceFactory(CreatePointerFuncFactory create_func) {
    rtsp_source_factory = create_func;
}

RTSPSourceFactory* RTSPSourceFactory::Create() {
    if (rtsp_source_factory) {
        return rtsp_source_factory();
    } else {
        return nullptr;
    }
}

RTSPManagement::RTSPManagement(const std::string &uri, const std::map<std::string,std::string> &opts):
    m_envi(m_stop),
    m_connection(m_envi, this, uri.c_str(), RTSPConnection::decodeTimeoutOption(opts), RTSPConnection::decodeRTPTransport(opts), 1)
{
    this->source_factory = RTSPSourceFactory::Create();
    rtsp_source_factory()->registerRTSPControl(this);
}

RTSPManagement::~RTSPManagement()
{
    this->stopRTSP();
}

//function set info RTSPConnection
void RTSPManagement::startRTSP() {
    m_thread = std::thread(&RTSPManagement::CapturerThread,this);
}

void RTSPManagement::stopRTSP() {
    m_envi.stop();
    m_thread.join();
}

void RTSPManagement::CapturerThread() {
    m_envi.mainloop();
}

//override RTSPConnection:Callback
bool RTSPManagement::onNewSession(const char* id, const char* media, const char* codec, const char* sdp) {
    bool success = false;
    CheckCodecType(codec);
    std::vector<std::vector<uint8_t>> frames;
    if (strcmp(media, "video") == 0) {
        if ( (m_codec ==  common::kCodecH264) ||
             (m_codec ==  common::kCodecH265) ||
             (m_codec ==  common::kCodecHEVC) ) {
            success = true;
        } else if (m_codec ==  common::kCodecJPEG)
        {
            std::cout << "Do not support JPEG Codec" << std::endl;
            success = false;
        }
        else if (m_codec ==  common::kCodecVP9)
        {
            std::cout << "Do not support VP9 Codec" << std::endl;
            success = false;
        }
    }
    return success;
}

bool RTSPManagement::onData(const char* id, unsigned char* buffer, ssize_t size, struct timeval presentationTime) {
    bool success = false;
    switch (m_codec) {
        case common::kCodecH265:
        case common::kCodecHEVC:
        case common::kCodecJPEG:
        case common::kCodecVP9:
        default:
            break;
        case common::kCodecH264:
            common::NaluType type = common::getNaluType(buffer[sizeof(H26X_marker)]);
            if ( type == common::kSps) {
                m_cfg.clear();
                m_cfg.insert(m_cfg.end(), buffer, buffer + size);
                std::cout << "RTSPVideoCapturer:onData SLICE NALU:" << (int)type << std::endl;
                
            } else if ( type == common::kPps) {
                std::cout << "RTSPVideoCapturer:onData SLICE NALU:" << (int)type << std::endl;
                m_cfg.insert(m_cfg.end(), buffer, buffer + size);
                
            }else if (type == common::kSei) {
                //just ignore for now
                std::cout << "RTSPVideoCapturer:onData SLICE NALU:" << (int)type << std::endl;
                
            } else {
                std::vector<uint8_t> m_content;
                if (type == kIdr) {
                    std::cout << "RTSPVideoCapturer:onData SLICE NALU:" << (int)type << std::endl;
                    m_content.insert(m_content.end(), m_cfg.begin(), m_cfg.end());
                } else {
                    std::cout << "RTSPVideoCapturer:onData SLICE NALU:" << (int)type << std::endl;
                }
                m_content.insert(m_content.end(), buffer, buffer + size);
                uint64_t presentTime = getPresentationTime(presentationTime);
                FrameEncoded* frame = new FrameEncoded(m_content.data(), m_content.size(), presentTime);
                rtsp_source_factory()->onData(frame);
            }

            return true;
    }
    return success;
}

uint64_t RTSPManagement::getPresentationTime(struct timeval presentationTime) {
    uint64_t ts = presentationTime.tv_sec;
    ts = ts * 1000 + presentationTime.tv_usec / 1000;
    return ts;
}

void RTSPManagement::onError(RTSPConnection& connection, const char* error) {
    std::cout << "RTSPVideoCapturer:onError url:" <<  " error:" << error << std::endl;
    connection.start(1);
}

