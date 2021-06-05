//
//  BYOnvifResultItem.m
//  BYOnvif
//
//  Created by By's Mac Book Pro on 2021/5/31.
//

#import "BYOnvifResultItem.h"

@implementation BYOnvifResultItem

- (NSString *)authentedStreamUrlStr {
    return [self by_uri:self.streamUrlStr appendUserName:self.userName password:self.password];
}

- (NSString *)by_uri:(NSString *)uri
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

@end
