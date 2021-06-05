//
//  ViewController.m
//  BYOnvif
//
//  Created by By's Mac Book Pro on 2021/5/24.
//

#import "ViewController.h"
#import "BYIJKFFPlayerView.h"
#import "BYOnvifResultItem.h"
#import "BYOnvifTools.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *searchButton;
@property (nonatomic, strong) UIButton *getOnvifInfoButton;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;
@property (nonatomic, strong) UIButton *upButton;
@property (nonatomic, strong) UIButton *downButton;
@property (nonatomic, strong) UIButton *zoomInButton;
@property (nonatomic, strong) UIButton *zoomOutButton;

@property (nonatomic, strong) NSString *deviceUrlStr;
@property (nonatomic, strong) NSString *authentedStreamUrlStr;
@property (nonatomic, strong) UIView *playerContentView;
@property (nonatomic, strong) BYIJKFFPlayerView *playerView;

@property (nonatomic, strong) BYOnvifResultItem *resultItem;

@end

static NSString *kUserName = @"admin";
static NSString *kPassword = @"ky123456";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self p_setupSubViews];
}

#pragma mark - ---- Private method
- (void)p_initPlayer {
    NSString *urlStr = self.authentedStreamUrlStr;
    if (urlStr.length < 1) {
        urlStr = @"rtmp://58.200.131.2:1935/livetv/cctv1";
    }
    [self.playerView updatePlayerWithUrlStr:urlStr];
}

#pragma mark - ---- Button action
- (void)a_action:(UIButton *)button {
    NSInteger tag = button.tag;
    switch (tag) {
        case 1: {
            [BYOnvifTools detectDeviceResult:self.resultItem];
            self.deviceUrlStr = self.resultItem.deviceUrlStr;
        }
            break;
        case 2: {
            if (self.deviceUrlStr.length < 1) {
                return;
            }
            
            [BYOnvifTools getCapabilityWithDeviceAddr:self.deviceUrlStr userName:kUserName password:kPassword result:self.resultItem];
            if (self.resultItem.mediaUrlStr.length < 1) {
                return;
            }
            [BYOnvifTools getProfilesWithAddr:self.resultItem.mediaUrlStr userName:kUserName password:kPassword result:self.resultItem];
            if (self.resultItem.profileTokenStr.length < 1) {
                return;
            }
            [BYOnvifTools getStreamUriWithAddr:self.resultItem.mediaUrlStr profileToken:self.resultItem.profileTokenStr userName:kUserName password:kPassword result:self.resultItem];
            if (self.resultItem.authentedStreamUrlStr.length < 1) {
                return;
            }
            self.authentedStreamUrlStr = self.resultItem.authentedStreamUrlStr;
            
            [self p_initPlayer];
        }
            break;
        case 3:
        case 4:
        case 5:
        case 6:
        case 11:
        case 12: {
            if (self.resultItem.ptzUrlStr.length < 1) {
                return;
            }
            double step = 0.2;
            if (tag == 11 || tag == 12) {
                step = 0.5;
            }
            BYPTZCmdType cmd = (BYPTZCmdType)(tag - 2);
            [BYOnvifTools ptzRelativeMoveWithAddr:self.resultItem.ptzUrlStr profileToken:self.resultItem.profileTokenStr commond:cmd moveStep:step userName:kUserName password:kPassword];
            
        }
            break;
        default:
            break;
    }
}

#pragma mark - ---- Getter
- (UIButton *)searchButton {
    if (!_searchButton) {
        _searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_searchButton addTarget:self action:@selector(a_action:) forControlEvents:UIControlEventTouchUpInside];
        _searchButton.tag = 1;
        _searchButton.backgroundColor = [UIColor blueColor];
        [_searchButton setTitle:@"search" forState:UIControlStateNormal];
    }
    return _searchButton;
}

- (UIButton *)getOnvifInfoButton {
    if (!_getOnvifInfoButton) {
        _getOnvifInfoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_getOnvifInfoButton addTarget:self action:@selector(a_action:) forControlEvents:UIControlEventTouchUpInside];
        _getOnvifInfoButton.tag = 2;
        _getOnvifInfoButton.backgroundColor = [UIColor blueColor];
        [_getOnvifInfoButton setTitle:@"get info" forState:UIControlStateNormal];
    }
    return _getOnvifInfoButton;
}

- (UIButton *)leftButton {
    if (!_leftButton) {
        _leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_leftButton addTarget:self action:@selector(a_action:) forControlEvents:UIControlEventTouchUpInside];
        _leftButton.tag = 3;
        _leftButton.backgroundColor = [UIColor blueColor];
        [_leftButton setTitle:@"left" forState:UIControlStateNormal];
    }
    return _leftButton;
}

- (UIButton *)rightButton {
    if (!_rightButton) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightButton addTarget:self action:@selector(a_action:) forControlEvents:UIControlEventTouchUpInside];
        _rightButton.tag = 4;
        _rightButton.backgroundColor = [UIColor blueColor];
        [_rightButton setTitle:@"right" forState:UIControlStateNormal];
    }
    return _rightButton;
}

- (UIButton *)upButton {
    if (!_upButton) {
        _upButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_upButton addTarget:self action:@selector(a_action:) forControlEvents:UIControlEventTouchUpInside];
        _upButton.tag = 5;
        _upButton.backgroundColor = [UIColor blueColor];
        [_upButton setTitle:@"up" forState:UIControlStateNormal];
    }
    return _upButton;
}

- (UIButton *)downButton {
    if (!_downButton) {
        _downButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_downButton addTarget:self action:@selector(a_action:) forControlEvents:UIControlEventTouchUpInside];
        _downButton.tag = 6;
        _downButton.backgroundColor = [UIColor blueColor];
        [_downButton setTitle:@"down" forState:UIControlStateNormal];
    }
    return _downButton;
}

- (UIButton *)zoomInButton {
    if (!_zoomInButton) {
        _zoomInButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_zoomInButton addTarget:self action:@selector(a_action:) forControlEvents:UIControlEventTouchUpInside];
        _zoomInButton.tag = 11;
        _zoomInButton.backgroundColor = [UIColor blueColor];
        [_zoomInButton setTitle:@"zoom in" forState:UIControlStateNormal];
    }
    return _zoomInButton;
}

- (UIButton *)zoomOutButton {
    if (!_zoomOutButton) {
        _zoomOutButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_zoomOutButton addTarget:self action:@selector(a_action:) forControlEvents:UIControlEventTouchUpInside];
        _zoomOutButton.tag = 12;
        _zoomOutButton.backgroundColor = [UIColor blueColor];
        [_zoomOutButton setTitle:@"zoom out" forState:UIControlStateNormal];
    }
    return _zoomOutButton;
}

- (BYIJKFFPlayerView *)playerView {
    if (_playerView == nil) {
        _playerView = [[BYIJKFFPlayerView alloc] init];
    }
    return _playerView;
}

- (UIView *)playerContentView {
    if (!_playerContentView) {
        _playerContentView = [UIView new];
        _playerContentView.backgroundColor = [UIColor lightGrayColor];
    }
    return _playerContentView;
}

- (BYOnvifResultItem *)resultItem {
    if (!_resultItem) {
        _resultItem = [[BYOnvifResultItem alloc] init];
        _resultItem.userName = kUserName;
        _resultItem.password = kPassword;
    }
    return _resultItem;
}

#pragma mark - ---- UI
- (void)p_setupSubViews {
    [self.view addSubview:self.searchButton];
    [self.view addSubview:self.getOnvifInfoButton];
    
    [self.view addSubview:self.leftButton];
    [self.view addSubview:self.rightButton];
    
    [self.view addSubview:self.upButton];
    [self.view addSubview:self.downButton];
    
    [self.view addSubview:self.zoomInButton];
    [self.view addSubview:self.zoomOutButton];
    
    [self.view addSubview:self.playerContentView];
    [self.playerContentView addSubview:self.playerView];
    
    self.searchButton.frame = CGRectMake(50, 50, 100, 50);
    self.getOnvifInfoButton.frame = CGRectMake(250, 50, 100, 50);
    
    self.leftButton.frame = CGRectMake(50, 150, 100, 50);
    self.rightButton.frame = CGRectMake(250, 150, 100, 50);
    
    self.upButton.frame = CGRectMake(50, 250, 100, 50);
    self.downButton.frame = CGRectMake(250, 250, 100, 50);
    
    self.zoomInButton.frame = CGRectMake(50, 350, 100, 50);
    self.zoomOutButton.frame = CGRectMake(250, 350, 100, 50);
    
    self.playerContentView.frame = CGRectMake(50, 450, 300, 200);
    self.playerView.frame = CGRectMake(0, 0, 300, 200);
}

@end
