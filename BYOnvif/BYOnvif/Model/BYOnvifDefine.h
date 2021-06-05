//
//  BYOnvifDefine.h
//  Kapollo
//
//  Created by By's Mac Book Pro on 2021/5/13.
//

#ifndef BYOnvifDefine_h
#define BYOnvifDefine_h

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "soapH.h"
#include "wsaapi.h"
#include "wsseapi.h"

#define BY_ONVIF_ADDRESS_SIZE 100
#define BY_ADDRESS_SIZE 100

#define BY_SOAP_ASSERT     assert

#define BY_SOAP_TO         "urn:schemas-xmlsoap-org:ws:2005:04:discovery"
#define BY_SOAP_ACTION     "http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe"
//#define SOAP_ACTION     "http://docs.oasis-open.org/ws-dd/ns/discovery/2009/01/Probe"
// onvif规定的组播地址
#define BY_SOAP_MCAST_ADDR "soap.udp://239.255.255.250:3702"
// 寻找的设备范围
#define BY_SOAP_ITEM       ""
// 寻找的设备类型
#define BY_SOAP_TYPES      "dn:NetworkVideoTransmitter"
// socket超时时间（单秒秒）
#define BY_SOAP_SOCK_TIMEOUT    (20)

#define BY_Continuous_Move_Ip  "http://www.onvif.org/ver10/tptz/PanTiltSpaces/VelocityGenericSpace"
#define BY_Continuous_Zoom_Ip  "http://www.onvif.org/ver10/tptz/ZoomSpaces/VelocityGenericSpace"

#endif /* BYOnvifDefine_h */
