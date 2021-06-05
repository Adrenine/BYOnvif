//
//  BYOnvifResultItem.h
//  BYOnvif
//
//  Created by By's Mac Book Pro on 2021/5/31.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BYPTZCmdType){
    BYPTZCmdTypeNone = 0,
    BYPTZCmdTypeLeft = 1,
    BYPTZCmdTypeRight,
    BYPTZCmdTypeUp,
    BYPTZCmdTypeDown,
    BYPTZCmdTypeLeftUp,
    BYPTZCmdTypeLeftDown,
    BYPTZCmdTypeRightUp,
    BYPTZCmdTypeRightDown,
    BYPTZCmdTypeZoomIn,
    BYPTZCmdTypeZoomOut,
};

NS_ASSUME_NONNULL_BEGIN

@interface BYOnvifResultItem : NSObject

@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *ipStr;
@property (nonatomic, strong) NSString *deviceUrlStr;
@property (nonatomic, strong) NSString *mediaUrlStr;
@property (nonatomic, strong) NSString *ptzUrlStr;
@property (nonatomic, strong) NSString *streamUrlStr;
// 播放视频使用带认证字段的url
@property (nonatomic, strong, readonly) NSString *authentedStreamUrlStr;
@property (nonatomic, strong) NSString *profileTokenStr;

@end

NS_ASSUME_NONNULL_END
