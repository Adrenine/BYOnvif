//
//  BYOnvifUdpScannerTool.m
//  BYOnvifXml
//
//  Created by By's Mac Book Pro on 2021/5/31.
//

#import "BYOnvifUdpScannerTool.h"
#import "GCDAsyncUdpSocket.h"

@interface BYOnvifUdpScannerTool () <GCDAsyncUdpSocketDelegate>

@property (nonatomic, strong) GCDAsyncUdpSocket *byUDPSocket;

@end

@implementation BYOnvifUdpScannerTool

+ (instancetype)shareInstance {
    static BYOnvifUdpScannerTool *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self shareInstance];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)startWithSendUdpInfo:(NSString *)udpInfo {
    [self initReceiveUDPSocketWithUdpData:[udpInfo dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)startWithSendUdpData:(NSData *)data {
    [self initReceiveUDPSocketWithUdpData:data];
}

- (void)stop {
    if (self.byUDPSocket) {
        [self.byUDPSocket close];
        self.byUDPSocket.delegate = nil;
        self.byUDPSocket = nil;
    }
}

- (void)initReceiveUDPSocketWithUdpData:(NSData *)udpData{
    if (self.byUDPSocket) {
        [self.byUDPSocket close];
        self.byUDPSocket.delegate = nil;
        self.byUDPSocket = nil;
    }

    dispatch_queue_t queue = dispatch_queue_create("com.test.deviceScanner", DISPATCH_QUEUE_SERIAL);
    self.byUDPSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:queue];
    [self.byUDPSocket setIPv4Enabled:YES];
    [self.byUDPSocket setIPv6Enabled:NO];

    NSError *error;

    // 绑定响应端口
    BOOL bind = [self.byUDPSocket bindToPort:0 error:&error];
    if (!bind) {
        [self.byUDPSocket bindToPort:0 error:&error];
    }
    
    BOOL broad = [self.byUDPSocket enableBroadcast:YES error:&error];
    // 开启组播
    if (!broad) {
        [self.byUDPSocket enableBroadcast:YES error:&error];
    }

    // 加入组播
    BOOL join = [self.byUDPSocket joinMulticastGroup:BYOnvifMultiCastAddress error:&error];
    if (!join) {
        [self.byUDPSocket joinMulticastGroup:BYOnvifMultiCastAddress error:&error];
    }

    BOOL receive = [self.byUDPSocket beginReceiving:&error];
    // 开始接受数据
    if (!receive) {
        [self.byUDPSocket beginReceiving:&error];
    }
    
    // 发送广播
    [self.byUDPSocket sendData:udpData toHost:BYOnvifMultiCastAddress port:BYOnvifMultiCastPort withTimeout:10 tag:1704];

}

#pragma mark - ---- Delegate
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    NSString *aStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"Onvif search 接收到%@ 消息: %@",sock.connectedHost,aStr);
    if ([self.delegate respondsToSelector:@selector(d_udpSocket:didReceiveData:)]) {
        [self.delegate d_udpSocket:sock didReceiveData:data];
    }
}

@end
