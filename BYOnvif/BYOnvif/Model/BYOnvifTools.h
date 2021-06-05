//
//  BYOnvifTools.h
//  Kapollo
//
//  Created by By's Mac Book Pro on 2021/5/13.
//

#import <Foundation/Foundation.h>
#import "BYOnvifDefine.h"
#import "BYOnvifResultItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSInteger, BYOnvifInfoResultStatus) {
    BYOnvifInfoResultStatusUnkonw,
    BYOnvifInfoResultStatusGetCapabilityFail,
    BYOnvifInfoResultStatusGetProfileFail,
    BYOnvifInfoResultStatusGetStreamUriFail,
    BYOnvifInfoResultStatusSuccess,
};

@interface BYOnvifTools : NSObject

+ (int)detectDeviceResult:(BYOnvifResultItem *)resultItem;

+ (int)getCapabilityWithDeviceAddr:(NSString *)deviceXAddrStr
                          userName:(NSString *)userName
                          password:(NSString *)password
                            result:(BYOnvifResultItem *)resultItem;

+ (NSString *)getProfilesWithAddr:(NSString *)capabilityXAddr
                         userName:(NSString *)userName
                         password:(NSString *)password
                           result:(BYOnvifResultItem *)resultItem;

+ (int)getStreamUriWithAddr:(NSString *)mediaXAddrStr
               profileToken:(NSString *)profileTokenStr
                   userName:(NSString *)userName
                   password:(NSString *)password
                     result:(BYOnvifResultItem *)resultItem;

+ (int)ptzStopMoveWithAddr:(NSString *)ptzAddrStr
              profileToken:(NSString *)tokenStr
                  userName:(NSString *)userName
                  password:(NSString *)password;

/// 此方法为阻塞式方法
/// second 小于0，一直移动，需主动调用stop，second大于0，会阻塞second时间，自动stop
+ (int)ptzContinuousMoveWithAddr:(NSString *)ptzAddrStr
                    profileToken:(NSString *)tokenStr
                         commond:(BYPTZCmdType)cmd
                           speed:(float)speed
                        userName:(NSString *)userName
                        password:(NSString *)password
                      stopSecond:(int)second;

+ (int)ptzRelativeMoveWithAddr:(NSString *)ptzAddrStr
                  profileToken:(NSString *)tokenStr
                       commond:(BYPTZCmdType)commond
                      moveStep:(float)moveStep
                      userName:(NSString *)userName
                      password:(NSString *)password;

@end

NS_ASSUME_NONNULL_END
