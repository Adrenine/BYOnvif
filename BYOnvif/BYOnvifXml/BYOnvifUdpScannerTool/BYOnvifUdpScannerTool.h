//
//  BYOnvifUdpScannerTool.h
//  BYOnvifXml
//
//  Created by By's Mac Book Pro on 2021/5/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GCDAsyncUdpSocket;

@protocol OnvifScannerToolsDelegate <NSObject>

- (void)d_udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data;

@end

static NSString * BYOnvifMultiCastAddress = @"239.255.255.250";
static NSUInteger BYOnvifMultiCastPort = 3702;

@interface BYOnvifUdpScannerTool : NSObject

+ (instancetype)shareInstance;

@property (nonatomic, weak) id<OnvifScannerToolsDelegate> delegate;

- (void)startWithSendUdpInfo:(NSString *)udpInfo;
- (void)startWithSendUdpData:(NSData *)data;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
