//
//  BYOnvifTools.m
//  Kapollo
//
//  Created by By's Mac Book Pro on 2021/5/13.
//

#import "BYOnvifTools.h"

@implementation BYOnvifTools

#pragma mark - ---- Soap life cycle
static void * by_mallocSoap(struct soap *soap, unsigned int n) {
    void *p = NULL;
    
    if (n > 0) {
        p = soap_malloc(soap, n);
        BY_SOAP_ASSERT(NULL != p);
        memset(p, 0x00 ,n);
    }
    return p;
}

static struct soap * by_newSoap(int timeout) {
    struct soap *soap = NULL;// soap环境变量
    soap = soap_new();
    BY_SOAP_ASSERT(NULL != soap);
    
    soap_set_namespaces(soap, namespaces); // 设置soap的namespaces
    soap->recv_timeout    = timeout;  // 设置超时（超过指定时间没有数据就退出）
    soap->send_timeout    = timeout;
    soap->connect_timeout = timeout;
    
#if defined(__linux__) || defined(__linux)   // 参考https://www.genivia.com/dev.html#client-c的修改：
    soap->socket_flags = MSG_NOSIGNAL;   // To prevent connection reset errors
#endif
    
    soap_set_mode(soap, SOAP_C_UTFSTRING);   // 设置为UTF-8编码，否则叠加中文OSD会乱码
    
    return soap;
}

static void by_deleteSoap(struct soap *soap) {
    soap_destroy(soap); // remove deserialized class instances (C++ only)
    soap_end(soap);     // Clean up deserialized data (except class instances) and temporary data
    soap_done(soap);    // Reset, close communications, and remove callbacks
    soap_free(soap);    // Reset and deallocate the context created with soap_new or soap_copy
}

/// 初始化soap描述消息头
static void by_initHeader(struct soap *soap) {
    struct SOAP_ENV__Header *header = NULL;
    
    BY_SOAP_ASSERT(NULL != soap);
    
    header = (struct SOAP_ENV__Header *)by_mallocSoap(soap, sizeof(struct SOAP_ENV__Header));
    soap_default_SOAP_ENV__Header(soap, header);
    header->wsa__MessageID = (char*)soap_wsa_rand_uuid(soap);
    header->wsa__To        = (char*)by_mallocSoap(soap, strlen(BY_SOAP_TO) + 1);
    header->wsa__Action    = (char*)by_mallocSoap(soap, strlen(BY_SOAP_ACTION) + 1);
    strcpy(header->wsa__To, BY_SOAP_TO);
    strcpy(header->wsa__Action, BY_SOAP_ACTION);
    soap->header = header;
    
    return;
}

/// 初始化探测设备的范围和类型
static void by_initProbeType(struct soap *soap, struct wsdd__ProbeType *probe) {
    struct wsdd__ScopesType *scope = NULL;                                      // 用于描述查找哪类的Web服务
    
    BY_SOAP_ASSERT(NULL != soap);
    BY_SOAP_ASSERT(NULL != probe);
    
    scope = (struct wsdd__ScopesType *)by_mallocSoap(soap, sizeof(struct wsdd__ScopesType));
    soap_default_wsdd__ScopesType(soap, scope);                                 // 设置寻找设备的范围
    scope->__item = (char*)by_mallocSoap(soap, strlen(BY_SOAP_ITEM) + 1);
    strcpy(scope->__item, BY_SOAP_ITEM);
    
    memset(probe, 0x00, sizeof(struct wsdd__ProbeType));
    soap_default_wsdd__ProbeType(soap, probe);
    probe->Scopes = scope;
    probe->Types  = (char*)by_mallocSoap(soap, strlen(BY_SOAP_TYPES) + 1);     // 设置寻找设备的类型
    strcpy(probe->Types, BY_SOAP_TYPES);
    
    return;
}

#pragma mark - ---- Public method
+ (int)detectDeviceResult:(BYOnvifResultItem *)resultItem {
    int i;
    int result = 0;
    unsigned int count = 0;     // 搜索到的设备个数
    struct soap *soap = NULL;   // soap环境变量
    struct wsdd__ProbeType      req;    // 用于发送Probe消息
    struct __wsdd__ProbeMatches rep;    // 用于接收Probe应答
    struct wsdd__ProbeMatchType *probeMatch;
    
    soap = by_newSoap(BY_SOAP_SOCK_TIMEOUT);
    BY_SOAP_ASSERT(NULL != soap);
    
    by_initHeader(soap);            // 设置消息头描述
    by_initProbeType(soap, &req);   // 设置寻找的设备的范围和类型
    result = soap_send___wsdd__Probe(soap, BY_SOAP_MCAST_ADDR, NULL, &req);  // 向组播地址广播Probe消息
    while (SOAP_OK == result)   {   // 开始循环接收设备发送过来的消息
        memset(&rep, 0x00, sizeof(rep));
        result = soap_recv___wsdd__ProbeMatches(soap, &rep);
        BOOL isOk = [self p_soap:soap checkError:result string:@"ProbeMatches"];
        if (!isOk) {
            if (NULL != soap) {
                by_deleteSoap(soap);
            }
            return result;
        }
        NSString *urlStr = nil;
        // 成功接收到设备的应答消息
        if (NULL != rep.wsdd__ProbeMatches) {
            count += rep.wsdd__ProbeMatches->__sizeProbeMatch;
            for(i = 0; i < rep.wsdd__ProbeMatches->__sizeProbeMatch; i++) {
                probeMatch = rep.wsdd__ProbeMatches->ProbeMatch + i;
                char * url = probeMatch->XAddrs;
                NSString *tempUrl = [self p_stringFromChars:url];
                if([tempUrl containsString:@"http"] || [tempUrl containsString:@"https"]){
                    // 海康设备要提取第一个url
                    NSArray *array = [tempUrl componentsSeparatedByString:@" "];
                    urlStr = array.count > 0 ? array.firstObject : nil;
                    
                    break;  //找到设备
                }
            }
        }
        if (urlStr.length > 0) {
            NSLog(@"detectDevice %@",urlStr);
            resultItem.deviceUrlStr = urlStr;
            break;  //找到一个设备就不再探寻
        }
    }
    
    if (NULL != soap) {
        by_deleteSoap(soap);
    }
    return result;
}

/// 获取设备能力
/// @param deviceXAddrStr 设备地址
/// @param userName userName
/// @param password password
+ (int)getCapabilityWithDeviceAddr:(NSString *)deviceXAddrStr
                          userName:(NSString *)userName
                          password:(NSString *)password
                            result:(BYOnvifResultItem *)resultItem {
    if (deviceXAddrStr.length< 1 || userName.length < 1) {
        return -1;
    }
    int result = 0;
    char *addr = [self p_charsFromString:deviceXAddrStr];
    struct soap *soap = NULL;
    struct _tds__GetCapabilities            req;
    struct _tds__GetCapabilitiesResponse    rep;
    
    soap = by_newSoap(BY_SOAP_SOCK_TIMEOUT);
    BY_SOAP_ASSERT(NULL != soap);
    
    [self p_authSoap:soap username:userName password:password];
    
    memset(&req, 0x00, sizeof(req));
    memset(&rep, 0x00, sizeof(rep));
    result = soap_call___tds__GetCapabilities(soap, addr, NULL, &req, &rep);
    
    BOOL isOk = [self p_soap:soap checkError:result string:@"GetCapabilities"];
    if (!isOk) {
        if (NULL != soap) {
            by_deleteSoap(soap);
        }
        return result;
    }
    NSLog(@"===>\nDevice address : %s\n<===\n",rep.Capabilities->Device->XAddr);
    NSLog(@"===>\nPTZ address : %s\n<===\n",rep.Capabilities->PTZ->XAddr);
    NSLog(@"===>\nMedia address : %s\n<===\n",rep.Capabilities->Media->XAddr);
    
    resultItem.deviceUrlStr = [self p_stringFromChars:rep.Capabilities->Device->XAddr];
    resultItem.mediaUrlStr = [self p_stringFromChars:rep.Capabilities->Media->XAddr];
    resultItem.ptzUrlStr = [self p_stringFromChars:rep.Capabilities->PTZ->XAddr];
    
    if (NULL != soap) {
        by_deleteSoap(soap);
    }
    return result;
}

/// 获取描述文件信息
/// @param capabilityXAddr 设备能力地址
/// @param userName userName
/// @param password password
+ (NSString *)getProfilesWithAddr:(NSString *)capabilityXAddr
                         userName:(NSString *)userName
                         password:(NSString *)password
                           result:(BYOnvifResultItem *)resultItem  {
    if (capabilityXAddr.length< 1 || userName.length < 1) {
        return nil;
    }
    char *xAddr = [self p_charsFromString:capabilityXAddr];
    int result = 0;
    struct soap *soap = NULL;
    struct _trt__GetProfiles            req;
    struct _trt__GetProfilesResponse    rep;
    soap = by_newSoap(BY_SOAP_SOCK_TIMEOUT);
    BY_SOAP_ASSERT(NULL != soap);
    
    [self p_authSoap:soap username:userName password:password];
    
    memset(&req, 0x00, sizeof(req));
    memset(&rep, 0x00, sizeof(rep));
    result = soap_call___trt__GetProfiles(soap, xAddr, NULL, &req, &rep);
    
    BOOL isOk = [self p_soap:soap checkError:result string:@"GetProfiles"];
    if (!isOk) {
        if (NULL != soap) {
            by_deleteSoap(soap);
        }
        return nil;
    }
    
    NSLog(@"===>\nProfiles name : %s\n<===\n",rep.Profiles->Name);
    NSLog(@"===>\nProfiles token : %s\n<===\n",rep.Profiles->token);
    
    NSString *token = @"";
    if (rep.Profiles->token != NULL) {
        token = [self p_stringFromChars:rep.Profiles->token];
    }
    if (token.length > 0) {
        resultItem.profileTokenStr = token;
    }
    
    if (NULL != soap) {
        by_deleteSoap(soap);
    }
    
    return token;
}

/// 获取设备码流地址(RTSP)
/// @param mediaXAddrStr 媒体服务地址
/// @param profileTokenStr the media profile token
/// @param userName userName
/// @param password password
+ (int)getStreamUriWithAddr:(NSString *)mediaXAddrStr
               profileToken:(NSString *)profileTokenStr
                   userName:(NSString *)userName
                   password:(NSString *)password
                     result:(BYOnvifResultItem *)resultItem {
    if (mediaXAddrStr.length< 1 || profileTokenStr.length < 1 || userName.length < 1) {
        return -1;
    }
    char *MediaXAddr = [self p_charsFromString:mediaXAddrStr];
    char *ProfileToken = [self p_charsFromString:profileTokenStr];
    int result = 0;
    struct soap *soap = NULL;
    struct tt__StreamSetup              ttStreamSetup;
    struct tt__Transport                ttTransport;
    struct _trt__GetStreamUri           req;
    struct _trt__GetStreamUriResponse   rep;
    
    soap = by_newSoap(BY_SOAP_SOCK_TIMEOUT);
    BY_SOAP_ASSERT(NULL != soap);
    
    memset(&req, 0x00, sizeof(req));
    memset(&rep, 0x00, sizeof(rep));
    memset(&ttStreamSetup, 0x00, sizeof(ttStreamSetup));
    memset(&ttTransport, 0x00, sizeof(ttTransport));
    ttStreamSetup.Stream                = tt__StreamType__RTP_Unicast;
    ttStreamSetup.Transport             = &ttTransport;
    ttStreamSetup.Transport->Protocol   = tt__TransportProtocol__RTSP;
    ttStreamSetup.Transport->Tunnel     = NULL;
    req.StreamSetup                     = &ttStreamSetup;
    req.ProfileToken                    = ProfileToken;
    
    [self p_authSoap:soap username:userName password:password];
    result = soap_call___trt__GetStreamUri(soap, MediaXAddr, NULL, &req, &rep);
    BOOL isOk = [self p_soap:soap checkError:result string:@"GetStreamUri"];
    
    if (!isOk) {
        if (NULL != soap) {
            by_deleteSoap(soap);
        }
        return result;
    }
    
    
    if (NULL != rep.MediaUri->Uri) {
        
        NSString *uri = [self p_stringFromChars:rep.MediaUri->Uri];
        NSString *authedUri = [self p_uri:uri appendUserName:userName password:password];
        NSLog(@"===>\nGetStreamUri : %@\n<===\n",uri);
        NSLog(@"===>\nGetStreamAuthedUri : %@\n<===\n",authedUri);
        
        resultItem.streamUrlStr = uri;
    }
    
    
    if (NULL != soap) {
        by_deleteSoap(soap);
    }
    return result;
}

/// ptz停止移动
/// @param ptzAddrStr ptz地址
/// @param tokenStr token
/// @param userName userName
/// @param password password
+ (int)ptzStopMoveWithAddr:(NSString *)ptzAddrStr
              profileToken:(NSString *)tokenStr
                  userName:(NSString *)userName
                  password:(NSString *)password {
    if (ptzAddrStr.length< 1 || tokenStr.length < 1 || userName.length < 1) {
        return -1;
    }
    
    char *ptz_ip = [self p_charsFromString:ptzAddrStr];
    char *token = [self p_charsFromString:tokenStr];
    int result = -1;
    struct soap *soap = NULL;// pointer of soap
    struct _tptz__Stop req;
    struct _tptz__StopResponse resp;
    
    enum xsd__boolean stop_rote = xsd__boolean__true_;
    enum xsd__boolean stop_foci = xsd__boolean__false_;
    
    req.PanTilt = &stop_rote;
    req.Zoom = &stop_foci;
    req.ProfileToken = token;
    
    soap = by_newSoap(BY_SOAP_SOCK_TIMEOUT);
    BY_SOAP_ASSERT(NULL != soap);
    [self p_authSoap:soap username:userName password:password];
    
    
    result = soap_call___tptz__Stop(soap , ptz_ip , NULL , &req , &resp);
    
    
    BOOL isOK = [self p_soap:soap checkError:result string:@"ONVIF_PTZStopMove"];
    if (!isOK) {
        if (NULL != soap) {
            by_deleteSoap(soap);
        }
        return result;
    }
    
    if (NULL != soap) {
        by_deleteSoap(soap);
    }
    return result;
}

/// 获取当前ptz的位置以及状态
/// @param ptzXAddrStr ptz地址
/// @param tokenStr token
/// @param userName userName
/// @param password password
+ (int)getPTZStatusWithAddr:(NSString *)ptzXAddrStr
               profileToken:(NSString *)tokenStr
                   userName:(NSString *)userName
                   password:(NSString *)password {
    if (ptzXAddrStr.length< 1 || tokenStr.length < 1 || userName.length < 1) {
        return -1;
    }
    
    char * ptzXAddr = [self p_charsFromString:ptzXAddrStr];
    char * ProfileToken = [self p_charsFromString:tokenStr];
    int result = 0;
    struct soap *soap = NULL;
    struct _tptz__GetStatus           getStatus;
    struct _tptz__GetStatusResponse   getStatusResponse;
    soap = by_newSoap(BY_SOAP_SOCK_TIMEOUT);
    BY_SOAP_ASSERT(NULL != soap);
    
    [self p_authSoap:soap username:userName password:password];
    
    getStatus.ProfileToken = ProfileToken;
    result = soap_call___tptz__GetStatus(soap, ptzXAddr, NULL, &getStatus, &getStatusResponse);
    BOOL isOk = [self p_soap:soap checkError:result string:@"ONVIF_PTZ_GetStatus"];
    if (!isOk) {
        if (NULL != soap) {
            by_deleteSoap(soap);
        }
        
        return result;
    }
    
    if(*getStatusResponse.PTZStatus->MoveStatus->PanTilt == tt__MoveStatus__IDLE){
        NSLog(@"===>\n空闲 ...\n<===\n ");
    }else if(*getStatusResponse.PTZStatus->MoveStatus->PanTilt == tt__MoveStatus__MOVING){
        NSLog(@"===>\n移动中 ...\n<===\n ");
    }else if(*getStatusResponse.PTZStatus->MoveStatus->PanTilt == tt__MoveStatus__UNKNOWN){
        NSLog(@"===>\n未知 ...\n<===\n ");
    }
    
    NSLog(@"===>\n当前p: %f<===\n ", getStatusResponse.PTZStatus->Position->PanTilt->x);
    NSLog(@"===>\n当前t: %f<===\n ", getStatusResponse.PTZStatus->Position->PanTilt->y);
    NSLog(@"===>\n当前z: %f<===\n ", getStatusResponse.PTZStatus->Position->Zoom->x);
    
    if (NULL != soap) {
        by_deleteSoap(soap);
    }
    
    return result;
}

/// ptz相对移动
/// @param ptzAddrStr ptz地址
/// @param tokenStr token
/// @param commond 移动方向
/// @param moveStep 移动步长【0-1】
/// @param userName userName
/// @param password password
+ (int)ptzRelativeMoveWithAddr:(NSString *)ptzAddrStr
                  profileToken:(NSString *)tokenStr
                       commond:(BYPTZCmdType)commond
                      moveStep:(float)moveStep
                      userName:(NSString *)userName
                      password:(NSString *)password {
    if (ptzAddrStr.length< 1 || tokenStr.length < 1 || userName.length < 1) {
        return -1;
    }
    
    struct soap *soap = NULL;
    soap = by_newSoap(BY_SOAP_SOCK_TIMEOUT);
    
    char *ptzXAddr = [self p_charsFromString:ptzAddrStr];
    char *token = [self p_charsFromString:tokenStr];
    
    struct _tptz__RelativeMove *relativeMove = soap_new__tptz__RelativeMove(soap, -1);
    struct _tptz__RelativeMoveResponse *relativeMoveResponse = soap_new__tptz__RelativeMoveResponse(soap, -1);
    
    relativeMove->ProfileToken = token;
    struct tt__PTZVector *translation = soap_new_tt__PTZVector(soap, -1);
    relativeMove->Translation = translation;
    struct tt__Vector2D* panTilt = soap_new_tt__Vector2D(soap, -1);
    relativeMove->Translation->PanTilt = panTilt;
    struct tt__Vector1D* zoom = soap_new_tt__Vector1D(soap, -1);
    relativeMove->Translation->Zoom = zoom;
    struct tt__PTZSpeed* speed = soap_new_tt__PTZSpeed(soap, -1);
    relativeMove->Speed = speed;
    //    relativeMove->Translation->PanTilt->space = "http://www.onvif.org/ver10/tptz/PanTiltSpaces/VelocityGenericSpace";
    
    if(moveStep >= 1) {
        moveStep = 0.99999;
    }
    moveStep /= 10;
    
    switch(commond) {
        case BYPTZCmdTypeLeft:
            relativeMove->Translation->PanTilt->x = moveStep;
            break;
        case BYPTZCmdTypeRight:
            relativeMove->Translation->PanTilt->x = -moveStep;
            break;
        case BYPTZCmdTypeUp:
            relativeMove->Translation->PanTilt->y = -moveStep;
            break;
        case BYPTZCmdTypeDown:
            relativeMove->Translation->PanTilt->y = moveStep;
            break;
        case BYPTZCmdTypeLeftUp:
            relativeMove->Translation->PanTilt->x = moveStep;
            relativeMove->Translation->PanTilt->y = -moveStep;
            break;
        case BYPTZCmdTypeLeftDown:
            relativeMove->Translation->PanTilt->x = moveStep;
            relativeMove->Translation->PanTilt->y = moveStep;
            break;
        case BYPTZCmdTypeRightUp:
            relativeMove->Translation->PanTilt->x = -moveStep;
            relativeMove->Translation->PanTilt->y = -moveStep;
            break;
        case BYPTZCmdTypeRightDown:
            relativeMove->Translation->PanTilt->x = -moveStep;
            relativeMove->Translation->PanTilt->y = moveStep;
            break;
        case BYPTZCmdTypeZoomIn:
            relativeMove->Translation->Zoom->x = moveStep;
            break;
        case BYPTZCmdTypeZoomOut:
            relativeMove->Translation->Zoom->x = -moveStep;
            break;
        default:
            
            break;
    }
    
    [self p_authSoap:soap username:userName password:password];
    int result = soap_call___tptz__RelativeMove(soap, ptzXAddr, NULL, relativeMove, relativeMoveResponse);
    if(SOAP_OK == result) {
        NSLog(@"RelativeMove----OK\n");
    }
    else {
        NSLog(@"RelativeMove----faild\n");
        NSLog(@"soap error: %d--%d, %s, %s\n", __LINE__, soap->error, *soap_faultcode(soap), *soap_faultstring(soap));
    }
    return result;
}

/// ptz持续移动
/// @param ptzAddrStr ptz地址
/// @param tokenStr token
/// @param cmd 移动方向
/// @param speed 移动速度【0-1】
/// @param userName userName
/// @param password password
/// @param second 移动持续时间
+ (int)ptzContinuousMoveWithAddr:(NSString *)ptzAddrStr
                    profileToken:(NSString *)tokenStr
                         commond:(BYPTZCmdType)cmd
                           speed:(float)speed
                        userName:(NSString *)userName
                        password:(NSString *)password
                      stopSecond:(int)second {
    if (ptzAddrStr.length< 1 || tokenStr.length < 1 || userName.length < 1) {
        return -1;
    }
    
    struct soap *soap = NULL;
    soap = by_newSoap(BY_SOAP_SOCK_TIMEOUT);
    
    char *ptzXAddr = [self p_charsFromString:ptzAddrStr];
    char *token = [self p_charsFromString:tokenStr];
    struct _tptz__ContinuousMove* continuousMove = soap_new__tptz__ContinuousMove(soap, -1);
    struct _tptz__ContinuousMoveResponse* continuousMoveResponse = soap_new__tptz__ContinuousMoveResponse(soap, -1);
    continuousMove->ProfileToken = token;
    struct tt__PTZSpeed* velocity = soap_new_tt__PTZSpeed(soap, -1);
    continuousMove->Velocity = velocity;
    struct tt__Vector2D* panTilt = soap_new_tt__Vector2D(soap, -1);
    continuousMove->Velocity->PanTilt = panTilt;
    continuousMove->Velocity->PanTilt->space = "http://www.onvif.org/ver10/tptz/PanTiltSpaces/VelocityGenericSpace";
    struct tt__Vector1D* zoom = soap_new_tt__Vector1D(soap, -1);
    continuousMove->Velocity->Zoom = zoom;
    switch (cmd)
    {
        case BYPTZCmdTypeLeft:
            continuousMove->Velocity->PanTilt->x = -((float)speed / 10);
            continuousMove->Velocity->PanTilt->y = 0;
            break;
        case BYPTZCmdTypeRight:
            continuousMove->Velocity->PanTilt->x = ((float)speed / 10);
            continuousMove->Velocity->PanTilt->y = 0;
            break;
        case BYPTZCmdTypeUp:
            continuousMove->Velocity->PanTilt->x = 0;
            continuousMove->Velocity->PanTilt->y = ((float)speed / 10);
            break;
        case BYPTZCmdTypeDown:
            continuousMove->Velocity->PanTilt->x = 0;
            continuousMove->Velocity->PanTilt->y = -((float)speed / 10);
            break;
        case BYPTZCmdTypeZoomIn:
            continuousMove->Velocity->Zoom->x = ((float)speed / 20);
            break;
        case BYPTZCmdTypeZoomOut:
            continuousMove->Velocity->Zoom->x = -((float)speed / 20);
            break;
        default:
            break;
    }
    [self p_authSoap:soap username:userName password:password];
    int result = soap_call___tptz__ContinuousMove(soap,ptzXAddr, NULL,continuousMove,continuousMoveResponse);
    BOOL isOK = [self p_soap:soap checkError:result string:@"ONVIF_PTZContinuousMove"];
    /*    sleep(1); //如果当前soap被删除（或者发送stop指令），就会停止移动
     ONVIF_PTZStopMove(ptzXAddr, ProfileToken);*/
    if (second > 0) {
        sleep(second);
        [self ptzStopMoveWithAddr:ptzAddrStr profileToken:tokenStr userName:userName password:password];
    }
    if (!isOK) {
        if (NULL != soap) {
            by_deleteSoap(soap);
        }
        return result;
    }
    NSLog(@"ptzContinuousMove result %d",result);
    if (NULL != soap) {
        by_deleteSoap(soap);
    }
    return result;
}

#pragma mark - ---- Private method
#pragma mark - Tools
+ (char *)p_charsFromString:(NSString *)string {
    return (char*)[string cStringUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)p_stringFromChars:(char *)chars {
    return [NSString stringWithUTF8String:chars];
}

+ (NSString *)p_uri:(NSString *)uri
     appendUserName:(NSString *)userName
           password:(NSString *)password {
    
    //字条串是否包含有某字符串
    NSRange range = [uri rangeOfString:@"//"];
    if (range.location == NSNotFound) {
        return uri;
    } else {
        NSInteger index = range.location+2;
        
        NSMutableString *str = uri.mutableCopy;
        [str insertString:@"@" atIndex:index];
        [str insertString:password atIndex:index];
        [str insertString:@":" atIndex:index];
        [str insertString:userName atIndex:index];
        return str;
    }
}

+ (void)p_soap:(struct soap *)soap
printErrorInfo:(NSString *)str {
    if (str.length < 1) {
        NSLog(@"[soap] error: %d, %s, %s\n", soap->error, *soap_faultcode(soap), *soap_faultstring(soap));
    } else {
        NSLog(@"[soap] %@ error: %d, %s, %s\n", str, soap->error, *soap_faultcode(soap), *soap_faultstring(soap));
    }
    return;
}

+ (BOOL)p_soap:(struct soap *)soap
    checkError:(int)result
        string:(NSString *)string {
    if (SOAP_OK != (result) || SOAP_OK != (soap)->error) {
        [self p_soap:soap printErrorInfo:string];
        return NO;
    }
    return YES;
}

#pragma mark - Soap method
/// 设置认证信息 0表明成功，非0表明失败
/// @param soap soap
/// @param usernameStr username
/// @param passwordStr password
+ (BOOL)p_authSoap:(struct soap *)soap
          username:(NSString *)usernameStr
          password:(NSString *)passwordStr {
    if (usernameStr.length < 1) {
        return NO;
    }
    int result = 0;
    char *username = [self p_charsFromString:usernameStr];
    char *password = [self p_charsFromString:passwordStr];
    
    result = soap_wsse_add_UsernameTokenDigest(soap, NULL, username, password);
    BOOL isOk = [self p_soap:soap checkError:result string:@"add_UsernameTokenDigest"];
    if (!isOk) {
        return NO;
    }
    return YES;
}

@end

