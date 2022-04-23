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
    m_connection(m_envi, this, uri.c_str(), RTSPConnection::decodeTimeoutOption(opts), RTSPConnection::decodeRTPTransport(opts), 1),
    decode(new Decode())
{
    this->source_factory = RTSPSourceFactory::Create();
    rtsp_source_factory()->registerRTSPControl(this);
    std::cout << "ThienVU: " << uri << std::endl;
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
        if ( (m_codec ==  kCodecH264) ||
             (m_codec ==  kCodecH265) ||
             (m_codec ==  kCodecHEVC) ) {
            const char* pattern = "sprop-parameter-sets=";
            const char* sprop = strstr(sdp, pattern);
            if (sprop)
            {
                std::string sdpstr(sprop + strlen(pattern));
                size_t pos = sdpstr.find_first_of(" ;\r\n");
                if (pos != std::string::npos)
                {
                    sdpstr.erase(pos);
                }
                if (decode->DecodeSprop(sdpstr))
                {
                    std::vector<uint8_t> sps;
                    sps.insert(sps.end(), H26X_marker, H26X_marker + sizeof(H26X_marker));
                    sps.insert(sps.end(), decode->sps_nalu().begin(), decode->sps_nalu().end());
                    FrameEncoded* sps_data = new FrameEncoded(sps.data(),decode->sps_nalu_size());

                    std::vector<uint8_t> pps;
                    pps.insert(pps.end(), H26X_marker, H26X_marker + sizeof(H26X_marker));
                    pps.insert(pps.end(), decode->pps_nalu().begin(), decode->pps_nalu().end());
                    FrameEncoded* pps_data = new FrameEncoded(pps.data(),decode->pps_nalu_size());
                    rtsp_source_factory()->onDecodeParams(sps_data,pps_data);
                    success = true;
                }
            }
        } else if (m_codec ==  kCodecJPEG)
        {
            success = true;
        }
        else if (m_codec ==  kCodecVP9)
        {
            success = true;
        }
    }
    
    return success;
}

bool RTSPManagement::onData(const char* id, unsigned char* buffer, ssize_t size, struct timeval presentationTime) {
    bool success = false;
    switch (m_codec) {
        case kCodecH265:
        case kCodecHEVC:
        case kCodecJPEG:
        case kCodecVP9:
        default:
            break;
        case kCodecH264:
            uint64_t presentTime = getPresentationTime(presentationTime);
            FrameEncoded* frame = new FrameEncoded((uint8_t*) buffer,(size_t)size,presentTime);
            rtsp_source_factory()->onData(frame);
            return success;
    }
    return success;
}

uint64_t RTSPManagement::getPresentationTime(struct timeval presentationTime) {
    uint64_t ts = presentationTime.tv_sec;
    ts = ts * 1000 + presentationTime.tv_usec / 1000;
}

void RTSPManagement::onError(RTSPConnection& connection, const char* error) {
    std::cout << "RTSPVideoCapturer:onError url:" <<  " error:" << error << std::endl;
    connection.start(1);
}

