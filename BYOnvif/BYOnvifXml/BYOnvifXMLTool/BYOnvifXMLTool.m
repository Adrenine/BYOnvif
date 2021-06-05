//
//  BYOnvifXMLTool.m
//  BYOnvifXml
//
//  Created by By's Mac Book Pro on 2021/5/31.
//

#import "BYOnvifXMLTool.h"
#import <KissXML.h>
#import <CommonCrypto/CommonDigest.h>

@interface BYOnvifXMLTool ()

@property (nonatomic, strong) NSString *deviceUrlStr;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *password;

@property (nonatomic, strong) BYOnvifResultItem *resultItem;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSString *tempNonceStr;
@property (nonatomic, strong) NSString *tempTimeStr;

@property (nonatomic, strong) BYOnvifResultBlock getInfoComplete;

@end

@implementation BYOnvifXMLTool

+ (BYOnvifXMLTool *)createToolsWithDeviceUrlStr:(NSString *)deviceUrlStr
                                   userName:(NSString *)userName
                                   password:(NSString *)password {
    return [[self alloc] initWithDeviceUrlStr:deviceUrlStr userName:userName password:password];
}

+ (NSData *)dataFromXmlFile:(NSString *)name {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"xml"];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]];
    return data;
}

+ (DDXMLElement *)findXMLDocumentElement:(DDXMLElement *)element
                                 byTagName:(NSString *)tagName {
    DDXMLElement * d = nil;
    for (DDXMLElement *e in element.children) {
        if ([e.name isEqualToString:tagName]) {
            return e;
        }
        d = [BYOnvifXMLTool findXMLDocumentElement:e byTagName:tagName];
    }
    return d;
}

- (instancetype)initWithDeviceUrlStr:(NSString *)deviceUrlStr
                       userName:(NSString *)userName
                       password:(NSString *)password {
    if (self = [super init]) {
        _resultItem = [BYOnvifResultItem new];
        _deviceUrlStr = deviceUrlStr;
        _userName = userName;
        _password = password;
        _resultItem.userName = userName;
        _resultItem.password = password;
        _resultItem.deviceUrlStr = deviceUrlStr;
        
    }
    return self;
}

#pragma mark - ---- Public method
- (void)getOnvifInfoComplete:(BYOnvifResultBlock)complete {
    self.getInfoComplete = complete;
    [self net_getCapabilities];
}

- (void)ptzControlWithType:(BYPTZCmdType)type
                  complete:(BYOnvifPTZResultBlock)complete {
    double x = 0;
    double y = 0;
    double z = 0;
    switch (type) {
        case BYPTZCmdTypeLeft: {
            x = -0.1;
        }
            break;
        case BYPTZCmdTypeRight: {
            x = 0.1;
        }
            break;
        case BYPTZCmdTypeUp: {
            y = 0.1;
        }
            break;
        case BYPTZCmdTypeDown: {
            y = -0.1;
        }
            break;
        case BYPTZCmdTypeZoomIn: {
            z = -0.1;
        }
            break;
        case BYPTZCmdTypeZoomOut: {
            z = 0.1;
        }
            break;
        default:
            break;
    }
    NSString *xStr = [NSString stringWithFormat:@"%lf", x];
    NSString *yStr = [NSString stringWithFormat:@"%lf", y];
    NSString *zStr = [NSString stringWithFormat:@"%lf", z];
    
    NSData *sendData = [self p_createRelativeMoveXMLDataWithX:xStr y:yStr z:zStr];
    
    [self p_requestWithUrl:self.resultItem.ptzUrlStr body:sendData success:^(id response) {
        if (complete) {
            complete(YES);
        }
    } failure:^(NSError *error) {
        NSLog(@"ptzControl error: \n%@", error);
        if (complete) {
            complete(NO);
        }
    }];
}

#pragma mark - ---- network
- (void)net_getCapabilities {
    NSData *sendData = [self p_getDataFromXmlFile:@"getCapabilities"];
    [self p_requestWithUrl:self.deviceUrlStr body:sendData success:^(id response) {
        NSError *error = nil;
        DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:response options:0 error:&error];
        [self p_parseCapabilitiesWithXMLDocument:document];
    } failure:^(NSError *error) {
        NSLog(@"getCapabilities error: \n%@", error);
        if (self.getInfoComplete) {
            self.getInfoComplete(NO);
        }
    }];
}

- (void)net_getProfiles {
    NSData *sendData = [self p_createAuthentedProfilesXMLData];
    if (self.resultItem.mediaUrlStr.length > 1) {
        [self p_requestWithUrl:self.resultItem.mediaUrlStr body:sendData success:^(id response) {
            NSError *error = nil;
            DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:response options:0 error:&error];
            [self p_parseProfilesWithDocument:document];
        } failure:^(NSError *error) {
            NSLog(@"getProfiles error: \n%@", error);
            if (self.getInfoComplete) {
                self.getInfoComplete(NO);
            }
        }];
    }
}

- (void)net_getStreamUri {
    NSData *sendData = [self p_createAuthentedStreamUriXMLData];
    if (self.resultItem.mediaUrlStr.length > 1) {
        [self p_requestWithUrl:self.resultItem.mediaUrlStr body:sendData success:^(id response) {
            NSError *error = nil;
            DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:response options:0 error:&error];
            [self p_parseStreamUriWithDocument:document];
        } failure:^(NSError *error) {
            NSLog(@"getProfiles error: \n%@", error);
            if (self.getInfoComplete) {
                self.getInfoComplete(NO);
            }
        }];
    }
}

#pragma mark - ---- Private method
- (void)p_requestWithUrl:(NSString *)url
                    body:(NSData *)bodyData
                 success:(void(^)(id response))success
                 failure:(void(^)(NSError *error))failure {
    
    NSMutableURLRequest *request =
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                            cachePolicy:NSURLRequestUseProtocolCachePolicy
                        timeoutInterval:5.0];
    [request setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%ld",[bodyData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:bodyData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Onvif request error %@", error);
            if (failure) {
                failure(error);
            }
        }
        if (data.length > 0) {
//            NSLog(@"Onvif request data %@", data);
            if (success) {
                
                success(data);
            }
        }
    }];
    [dataTask resume];
}

- (DDXMLElement *)p_findXMLDocumentElement:(DDXMLElement *)element
                                 byTagName:(NSString *)tagName {
    return [BYOnvifXMLTool findXMLDocumentElement:element byTagName:tagName];
}

- (BOOL)p_replaceDocument:(DDXMLDocument *)document
       elementStringValue:(NSString *)valueStr
                byTagName:(NSString *)tagName {
    DDXMLElement *temp = nil;
    for (DDXMLElement *element in document.rootElement.children) {
        temp = [self p_findXMLDocumentElement:element byTagName:tagName];
        if (temp) {
            [temp setStringValue:valueStr];
            break;
        }
    }
    return temp != nil;
}

- (NSString *)p_encryptPassword {
    NSString *pwd = [self p_base64StringFromData:[self p_createSHA1DigestPassword]];
    return pwd;
}

- (NSData *)p_createSHA1DigestPassword {
    CC_SHA1_CTX hashObject;
    CC_SHA1_Init(&hashObject);
    NSString *time = [self p_getTimeStr];
    NSString *nonce = [self p_getNonceStr];
    
    NSData *d1 = [self p_dataFromBase64String:nonce];
    NSData *d2 = [self p_dataFromString:time];
    NSData *d3 = [self p_dataFromString:self.password];
    NSInteger len1 = d1.length;
    NSInteger len2 = d2.length;
    NSInteger len3 = d3.length;
    const void *b1 = [d1 bytes];
    const void *b2 = [d2 bytes];
    const void *b3 = [d3 bytes];

    CC_SHA1_Update(&hashObject,b1,(CC_LONG)len1);
    CC_SHA1_Update(&hashObject,b2,(CC_LONG)len2);
    CC_SHA1_Update(&hashObject,b3,(CC_LONG)len3);
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1_Final(digest, &hashObject);
    NSData *digestData = [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
//    NSLog(@"digestData %@",digestData);
    return digestData;
}

- (NSString *)p_getTimeStr {
    self.tempTimeStr = [self.dateFormatter stringFromDate:[NSDate date]];
    return self.tempTimeStr;
}

//返回32位大小写字母和数字
- (NSString *)p_getNonceStr {
    NSString *strSeed = @"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSString * result = [[NSMutableString alloc] initWithCapacity:32];
    for (int i = 0; i < 32; i++) {
        NSInteger index = arc4random() % (strSeed.length-1);
        char tempStr = [strSeed characterAtIndex:index];
        result = (NSMutableString *)[result stringByAppendingString:[NSString stringWithFormat:@"%c",tempStr]];
    }
    self.tempNonceStr = result;
    return result;
}

- (NSDateFormatter *)dateFormatter {
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    return dateFormatter;
}

#pragma mark - Create XML Data
- (NSData *)p_createAuthentedProfilesXMLData {
    if (self.userName.length < 1 || self.password.length < 1) {
        return nil;
    }
    NSData *sendData = [self p_getDataFromXmlFile:@"getProfiles"];
    NSError *error = nil;
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:sendData options:0 error:&error];
    BOOL suc = NO;
    suc = [self p_replaceDocument:document elementStringValue:self.userName byTagName:@"Username"];
    suc = [self p_replaceDocument:document elementStringValue:[self p_encryptPassword] byTagName:@"Password"];
    suc = [self p_replaceDocument:document elementStringValue:self.tempNonceStr byTagName:@"Nonce"];
    suc = [self p_replaceDocument:document elementStringValue:self.tempTimeStr byTagName:@"Created"];
    
    NSData *data = [document XMLData];
    document = [[DDXMLDocument alloc] initWithData:data options:0 error:&error];
//    NSLog(@"Authented Profiles XMLData %@",document);
    return data;
}

- (NSData *)p_createAuthentedStreamUriXMLData {
    if (self.userName.length < 1 || self.password.length < 1) {
        return nil;
    }
    NSData *sendData = [self p_getDataFromXmlFile:@"getStreamUri"];
    NSError *error = nil;
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:sendData options:0 error:&error];
    BOOL suc = NO;
    suc = [self p_replaceDocument:document elementStringValue:self.userName byTagName:@"Username"];
    suc = [self p_replaceDocument:document elementStringValue:[self p_encryptPassword] byTagName:@"Password"];
    suc = [self p_replaceDocument:document elementStringValue:self.tempNonceStr byTagName:@"Nonce"];
    suc = [self p_replaceDocument:document elementStringValue:self.tempTimeStr byTagName:@"Created"];
    suc = [self p_replaceDocument:document elementStringValue:self.resultItem.profileTokenStr byTagName:@"ProfileToken"];
    
    NSData *data = [document XMLData];
    document = [[DDXMLDocument alloc] initWithData:data options:0 error:&error];
//    NSLog(@"Authented Stream Uri XMLData %@",document);
    return data;
}

- (NSData *)p_createRelativeMoveXMLDataWithX:(NSString *)xStr
                                           y:(NSString *)yStr
                                           z:(NSString *)zStr {
    if (self.userName.length < 1 || self.password.length < 1) {
        return nil;
    }
    NSData *sendData = [self p_getDataFromXmlFile:@"relativeMove"];
    NSError *error = nil;
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:sendData options:0 error:&error];
    BOOL suc = NO;
    suc = [self p_replaceDocument:document elementStringValue:self.userName byTagName:@"Username"];
    suc = [self p_replaceDocument:document elementStringValue:[self p_encryptPassword] byTagName:@"Password"];
    suc = [self p_replaceDocument:document elementStringValue:self.tempNonceStr byTagName:@"Nonce"];
    suc = [self p_replaceDocument:document elementStringValue:self.tempTimeStr byTagName:@"Created"];
    suc = [self p_replaceDocument:document elementStringValue:self.resultItem.profileTokenStr byTagName:@"ProfileToken"];
    
    DDXMLElement *panTilt = nil;
    for (DDXMLElement *element in document.rootElement.children) {
        panTilt = [self p_findXMLDocumentElement:element byTagName:@"PanTilt"];
        if (panTilt) {
            break;
        }
    }
    
    DDXMLElement *zoom = nil;
    for (DDXMLElement *element in document.rootElement.children) {
        zoom = [self p_findXMLDocumentElement:element byTagName:@"Zoom"];
        if (zoom) {
            break;
        }
    }
    DDXMLNode *node = nil;
    if (panTilt) {
        for (DDXMLNode *n in panTilt.attributes) {
            if ([n.name isEqual:@"x"]) {
                node = n;
                break;
            }
        }
        [node setStringValue:xStr];
        
        for (DDXMLNode *n in panTilt.attributes) {
            if ([n.name isEqual:@"y"]) {
                node = n;
                break;
            }
        }
        [node setStringValue:yStr];
    }
    
    if (zoom) {
        for (DDXMLNode *n in zoom.attributes) {
            if ([n.name isEqual:@"x"]) {
                node = n;
                break;
            }
        }
        [node setStringValue:zStr];
    }
    
    NSData *data = [document XMLData];
    document = [[DDXMLDocument alloc] initWithData:data options:0 error:&error];
//    NSLog(@"Authented Stream Uri XMLData %@",document);
    return data;
}

#pragma mark - Data convert
- (NSData *)p_getDataFromXmlFile:(NSString *)name {
    return [BYOnvifXMLTool dataFromXmlFile:name];
}

- (NSString *)p_base64StringFromData:(NSData *)data {
    NSString * stringBase64 = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    return stringBase64;
}

- (NSData *)p_dataFromString:(NSString *)string {
    NSData *data =[string dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}

- (NSData *)p_dataFromBase64String:(NSString *)stringBase64 {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:stringBase64 options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return data;
}

#pragma mark - Parse XML Document
- (void)p_parseCapabilitiesWithXMLDocument:(DDXMLDocument *)document {
//    NSLog(@"parseCapabilities %@",document);
    DDXMLElement *ptz = nil;
    for (DDXMLElement *element in document.rootElement.children) {
        ptz = [self p_findXMLDocumentElement:element byTagName:@"tt:PTZ"];
        if (ptz) {
            break;
        }
    }
    if (ptz) {
        self.resultItem.ptzUrlStr = ptz.stringValue;
    }
    
    DDXMLElement *media = nil;
    for (DDXMLElement *element in document.rootElement.children) {
        media = [self p_findXMLDocumentElement:element byTagName:@"tt:Media"];
        if (media) {
            break;
        }
    }
    DDXMLElement *mediaAddr = [self p_findXMLDocumentElement:media byTagName:@"tt:XAddr"];
    
    if (mediaAddr) {
        self.resultItem.mediaUrlStr = mediaAddr.stringValue;
    }
    
    NSLog(@"ptzUrlStr %@ \n mediaUrlStr %@",self.resultItem.ptzUrlStr, self.resultItem.mediaUrlStr);
    
    [self net_getProfiles];
}

- (void)p_parseProfilesWithDocument:(DDXMLDocument *)document {
//    NSLog(@"parseProfiles %@",document);
    DDXMLElement *token = nil;
    for (DDXMLElement *element in document.rootElement.children) {
        token = [self p_findXMLDocumentElement:element byTagName:@"trt:Profiles"];
        if (token) {
            break;
        }
    }
    if (token) {
        DDXMLNode *node = nil;
        for (DDXMLNode *n in token.attributes) {
            if ([n.name isEqual:@"token"]) {
                node = n;
                break;
            }
        }
        self.resultItem.profileTokenStr = node.stringValue;
    }
    NSLog(@"profileTokenStr %@ \n",self.resultItem.profileTokenStr);
    [self net_getStreamUri];
}

- (void)p_parseStreamUriWithDocument:(DDXMLDocument *)document {
//    NSLog(@"parseStreamUri %@",document);
    DDXMLElement *stream = nil;
    
    for (DDXMLElement *element in document.rootElement.children) {
        stream = [self p_findXMLDocumentElement:element byTagName:@"trt:MediaUri"];
        if (stream) {
            break;
        }
    }
    DDXMLElement *streamAddr = [self p_findXMLDocumentElement:stream byTagName:@"tt:Uri"];
    
    if (streamAddr) {
        self.resultItem.streamUrlStr = streamAddr.stringValue;
    }
    NSLog(@"authented streamUrlStr %@ \n",self.resultItem.authentedStreamUrlStr);
    
    if (self.getInfoComplete) {
        self.getInfoComplete(YES);
    }
}

@end
