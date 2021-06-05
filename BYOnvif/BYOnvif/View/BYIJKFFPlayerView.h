//
//  BYIJKFFPlayerView.h
//  OnvifXMLDemo
//
//  Created by By's Mac Book Pro on 2021/6/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BYIJKFFPlayerView : UIView

- (void)updatePlayerWithUrlStr:(NSString *)urlStr;
- (void)reinitialPlayerWithUrlStr:(NSString *)urlStr;
- (void)playIJKPlayer;
- (void)pauseIJKPlayer;
- (void)removeIJKPlayer;

@end

NS_ASSUME_NONNULL_END
