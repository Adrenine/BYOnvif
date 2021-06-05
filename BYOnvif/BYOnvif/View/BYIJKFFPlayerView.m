//
//  BYIJKFFPlayerView.m
//  OnvifXMLDemo
//
//  Created by By's Mac Book Pro on 2021/6/1.
//

#import "BYIJKFFPlayerView.h"

#import <IJKMediaFramework/IJKFFMoviePlayerController.h>
#import <IJKMediaFramework/IJKMediaPlayback.h>

@interface BYIJKFFPlayerView()

@property (nonatomic, copy) NSString *mediaUrlStr;
@property (nonatomic, strong) IJKFFMoviePlayerController *player;

@end

@implementation BYIJKFFPlayerView

- (void)layoutSubviews {
    [super layoutSubviews];
    self.player.view.frame = self.bounds;
}


#pragma mark - Public Method
- (void)reinitialPlayerWithUrlStr:(NSString *)urlStr {
    self.mediaUrlStr = nil;
    [self updatePlayerWithUrlStr:urlStr];
}

- (void)updatePlayerWithUrlStr:(NSString *)urlStr {
    if ([self.mediaUrlStr isEqualToString:urlStr] && self.player != nil) {
        return;
    }
    self.mediaUrlStr = urlStr;
    NSURL * url = [NSURL URLWithString:urlStr];
    NSLog(@"video urlstring: ----> %@",urlStr);
    
    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
    
    IJKFFOptions *options = [self defaultOptions];
    
    [self removeIJKPlayer];
    
    //初始化播放器，播放在线视频
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:url withOptions:options];
    [self.player setPauseInBackground:YES];
    
    //设置自动播放模式
    self.player.shouldAutoplay = YES;
    self.player.shouldShowHudView = NO;
    self.player.playbackVolume = 0;
    
    //设置自适应布局
    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.player.view];
    
    //缩放模式为FILL
    self.player.scalingMode = IJKMPMovieScalingModeFill;
    
    // 启动预播放操作
    [self.player prepareToPlay];
    
    [IJKFFMoviePlayerController setLogReport:YES];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];

}

- (IJKFFOptions *)defaultOptions {
    IJKFFOptions *options = [IJKFFOptions optionsByDefault]; //使用默认配置
    [options setFormatOptionValue:@"tcp" forKey:@"rtsp_transport"];
    [options setFormatOptionIntValue:1024 forKey:@"probesize"];
    [options setPlayerOptionIntValue:100 forKey:@"max_cached_duration"];
    [options setPlayerOptionIntValue:0 forKey:@"packet-buffering"];  //  关闭播放器缓冲
    
    //#warning Test Set
    [options setFormatOptionIntValue:50000 forKey:@"analyzeduration"];
    [options setPlayerOptionIntValue:1 forKey:@"videotoolbox"];
    [options setCodecOptionIntValue:IJK_AVDISCARD_DEFAULT forKey:@"skip_loop_filter"];
    [options setCodecOptionIntValue:IJK_AVDISCARD_DEFAULT forKey:@"skip_frame"];
    [options setFormatOptionIntValue:0 forKey:@"infbuf"];
    [options setPlayerOptionIntValue:15 forKey:@"max-fps"];
    [options setFormatOptionValue:@"ijktcphook" forKey:@"http-tcp-hook"];
    return options;
}

- (void)playIJKPlayer {
    if (self.player) {
        [self.player play];
    }
}

- (void)pauseIJKPlayer {
    if (self.player) {
        [self.player pause];
    }
}

- (void)removeIJKPlayer {
    if (self.player) {
        [self.player.view removeFromSuperview];
        [self.player stop];
        [self.player shutdown];
        self.player = nil;
    }
}

@end
