//
//  BYOnvifXMLTool.h
//  BYOnvifXml
//
//  Created by By's Mac Book Pro on 2021/5/31.
//

#import <Foundation/Foundation.h>
#import "BYOnvifResultItem.h"

NS_ASSUME_NONNULL_BEGIN

@class DDXMLElement;

typedef void(^BYOnvifResultBlock)(BOOL);
typedef void(^BYOnvifPTZResultBlock)(BOOL);

@interface BYOnvifXMLTool : NSObject

@property (nonatomic, strong, readonly) BYOnvifResultItem *resultItem;

+ (BYOnvifXMLTool *)createToolsWithDeviceUrlStr:(NSString *)deviceUrlStr
                                userName:(NSString *)userName
                                password:(NSString *)password;

+ (NSData *)dataFromXmlFile:(NSString *)name;

+ (DDXMLElement *)findXMLDocumentElement:(DDXMLElement *)element
                               byTagName:(NSString *)tagName;

- (instancetype)initWithDeviceUrlStr:(NSString *)hostStr
                     userName:(NSString *)userName
                     password:(NSString *)password;

- (void)getOnvifInfoComplete:(BYOnvifResultBlock)complete;

- (void)ptzControlWithType:(BYPTZCmdType)type
                  complete:(BYOnvifPTZResultBlock)complete;

@end

NS_ASSUME_NONNULL_END
