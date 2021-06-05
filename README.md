# BYOnvif

# 目录
## [零、前言](#0)
## [一、Onvif协议的C语言实现](#1)
### &nbsp;&nbsp;[1. 参考文章](#1-1)
### &nbsp;&nbsp;[2. 集成方式](#1-2)
### &nbsp;&nbsp;[3. 方法调用](#1-3)
#### &nbsp;&nbsp;&nbsp;&nbsp;[a. 探寻设备](#1-3-a)
#### &nbsp;&nbsp;&nbsp;&nbsp;[b. 获取设备能力](#1-3-b)
#### &nbsp;&nbsp;&nbsp;&nbsp;[c. 获取token](#1-3-c)
#### &nbsp;&nbsp;&nbsp;&nbsp;[d. 获取推流url](#1-3-d)
#### &nbsp;&nbsp;&nbsp;&nbsp;[e. ptz停止移动](#1-3-e)
#### &nbsp;&nbsp;&nbsp;&nbsp;[f. ptz持续移动](#1-3-f)
#### &nbsp;&nbsp;&nbsp;&nbsp;[g. ptz相对移动](#1-3-g)
#### &nbsp;&nbsp;&nbsp;&nbsp;[h. ptz获取当前状态](#1-3-h)

## [二、Onvif协议收发XML实现](#2)
### &nbsp;&nbsp;[1. 集成方式](#2-1)
### &nbsp;&nbsp;[2. 方法调用](#2-2)
#### &nbsp;&nbsp;&nbsp;&nbsp;[a. 探寻设备](#2-2-a)
#### &nbsp;&nbsp;&nbsp;&nbsp;[b. 获取设备所有信息](#2-2-b)
#### &nbsp;&nbsp;&nbsp;&nbsp;[c. ptz控制](#2-2-c)
## [三、iOS下的注意事项](#3)

***

<h2 id='0'>零、前言</h2>

最近公司需要集成摄像头，采用Onvif协议，网上没找到可以直接运行的代码或者可运行的都需要大量积分，所以自己找资料参考实现，现将[代码](https://github.com/Adrenine/BYOnvif)和集成方式分享出来。</br>
若您非iOS平台，参考[Onvif协议的C语言实现](#1)即可；iOS平台建议使用[Onvif协议收发XML实现](#2)。</br>
本文不会详细讲解Onvif协议，简单介绍代码的使用。如果工程对您有用，希望能点一个⭐，谢谢。

<h2 id='1'>一、Onvif协议的C语言实现</h2>

<h3 id='1-1'>&nbsp;&nbsp;1. 参考文章</h3>

[ONVIF协议网络摄像机（IPC）客户端程序开发](https://blog.csdn.net/benkaoya/article/details/72424335)

<h3 id='1-2'>&nbsp;&nbsp;2. 集成方式</h3>

将以下文件拖入工程 **（非iOS工程需要自己集成openssl）**

![image.png](https://i.loli.net/2021/06/05/UYLdmaun1DC4GWQ.png)

![image.png](https://i.loli.net/2021/06/05/vdNPGKUW6nXu1aV.png)

![image.png](https://i.loli.net/2021/06/05/IqFDnLwckQ3WG5h.png)

<h3 id='1-3'>&nbsp;&nbsp;3. 方法调用</h3>

**（以下OC方法都是通过C语言实现，非iOS平台修改方法名，自己设置回调即可。）**

<h4 id='1-3-a'>&nbsp;&nbsp;&nbsp;&nbsp;a. 探寻设备</h3>

```objectivec
+ (int)detectDeviceResult:(BYOnvifResultItem *)resultItem;
```

<h4 id='1-3-b'>&nbsp;&nbsp;&nbsp;&nbsp;b. 获取设备能力</h3>

**注意：以下操作都需要鉴权，而且每次调用onvif库函数，都需要鉴权一次。**

传入上一步获取的设备地址 **（海康的设备地址需要做分割）**
通用设备可以获得：
  * media地址
  * ptz控制地址
```objectivec
+ (int)getCapabilityWithDeviceAddr:(NSString *)deviceXAddrStr
                          userName:(NSString *)userName
                          password:(NSString *)password
                            result:(BYOnvifResultItem *)resultItem;
```

<h4 id='1-3-c'>&nbsp;&nbsp;&nbsp;&nbsp;c. 获取token</h3>

传入上一步获取的media地址获取token
```objectivec
+ (NSString *)getProfilesWithAddr:(NSString *)capabilityXAddr
                         userName:(NSString *)userName
                         password:(NSString *)password
                           result:(BYOnvifResultItem *)resultItem;
```

<h4 id='1-3-d'>&nbsp;&nbsp;&nbsp;&nbsp;d. 获取推流url</h3>

传入media地址和上一步获取的token获得streamUrl，播放地址需要做用户名密码拼接，例如：
```c
rtsp://192.168.0.100/onvif/stream_service
```
拼接成
```
rtsp://username:password@192.168.0.100/onvif/stream_service
```
**（IJKPlayer默认不支持rtsp协议），需要修改编译选项**
```objectivec
+ (int)getStreamUriWithAddr:(NSString *)mediaXAddrStr
               profileToken:(NSString *)profileTokenStr
                   userName:(NSString *)userName
                   password:(NSString *)password
                     result:(BYOnvifResultItem *)resultItem;
```

<h4 id='1-3-e'>&nbsp;&nbsp;&nbsp;&nbsp;e. ptz停止移动</h3>

传入[获取设备能力](#1-3-b)获取到的ptz地址和[获取token](#1-3-c)获得的token，下面ptz方法传入都需要传入这两个参数，停止ptz移动
```objectivec
+ (int)ptzStopMoveWithAddr:(NSString *)ptzAddrStr
              profileToken:(NSString *)tokenStr
                  userName:(NSString *)userName
                  password:(NSString *)password;
```

<h4 id='1-3-f'>&nbsp;&nbsp;&nbsp;&nbsp;f. ptz持续移动</h3>

控制ptz持续移动，speed，移动速度[0, 1)的一个区间，stopSecond，持续移动多久停止，单位秒。
```objectivec
+ (int)ptzContinuousMoveWithAddr:(NSString *)ptzAddrStr
                    profileToken:(NSString *)tokenStr
                         commond:(BYPTZCmdType)cmd
                           speed:(float)speed
                        userName:(NSString *)userName
                        password:(NSString *)password
                      stopSecond:(int)second;
```

<h4 id='1-3-g'>&nbsp;&nbsp;&nbsp;&nbsp;g. ptz相对移动</h3>

ptz相对上一个位置移动一个步长，步长[0, 1)的一个区间
```objectivec
+ (int)ptzRelativeMoveWithAddr:(NSString *)ptzAddrStr
                  profileToken:(NSString *)tokenStr
                       commond:(BYPTZCmdType)commond
                      moveStep:(float)moveStep
                      userName:(NSString *)userName
                      password:(NSString *)password;
```

<h4 id='1-3-h'>&nbsp;&nbsp;&nbsp;&nbsp;h. ptz获取当前状态</h3>

获取当前ptz的状态（设备当前所处的坐标）
```objectivec
+ (int)getPTZStatusWithAddr:(NSString *)ptzXAddrStr
               profileToken:(NSString *)tokenStr
                   userName:(NSString *)userName
                   password:(NSString *)password;
```

<h2 id='2'>二、Onvif协议收发XML实现</h2>

<h3 id='2-1'>&nbsp;&nbsp;1. 集成方式</h3>

![image.png](https://i.loli.net/2021/06/05/IVQRyljHonD4Gbu.png)

![image.png](https://i.loli.net/2021/06/05/Q7wIA15dXMDt2xz.png)

<h3 id='2-2'>&nbsp;&nbsp;2. 方法调用</h3>
<h4 id='2-2-a'>&nbsp;&nbsp;&nbsp;&nbsp;a. 探寻设备</h3>

探寻设备使用UDPSocket，往239.255.255.250:3702发送探寻信息，等待组播返回信息

```objectivec
NSData *data = [BYOnvifXMLTool dataFromXmlFile:@"probe"];
[self.scannerTools startWithSendUdpData:data];
```

<h4 id='2-2-b'>&nbsp;&nbsp;&nbsp;&nbsp;b. 获取设备所有信息</h3>

将上一步探寻的设备地址和用户名密码传入
```objectivec
+ (BYOnvifXMLTool *)createToolsWithDeviceUrlStr:(NSString *)deviceUrlStr
                                userName:(NSString *)userName
                                password:(NSString *)password;
```
获取media地址，ptz地址，token信息，stream url
```objectivec
- (void)getOnvifInfoComplete:(BYOnvifResultBlock)complete;
```
所有信息保存在resultItem里。
```objectivec
@property (nonatomic, strong, readonly) BYOnvifResultItem *resultItem;
```

<h4 id='2-2-c'>&nbsp;&nbsp;&nbsp;&nbsp;c. ptz控制</h3>

```objectivec
- (void)ptzControlWithType:(BYPTZCmdType)type
                  complete:(BYOnvifPTZResultBlock)complete;
```
<h3 id='3'>三、iOS下的注意事项</h3>

* iOS 14以上，获取局域网内设备信息需要[申请权限](https://developer.apple.com/contact/request/networking-multicast)，操作步骤参考[iOS 14 UDP收不到广播处理](https://www.cnblogs.com/chao8888/p/13749383.html)；

* IJKMediaFramework.framework因文件大小没有上传至git，可根据自己需要编译或网上寻找资源，编译时注意添加rtsp支持，找不到也可留言或者邮箱联系。
***

### 联系方式
**邮箱：** xiebangyao_1994@163.com</br>
**相关账号：**
* [掘金 - Adrenine](https://juejin.im/user/57c39bfb79bc440063e5ad44)
* [简书 - Adrenine](https://www.jianshu.com/u/b20be2dcb0c3)
* [Blog - Adrenine](https://adrenine.github.io/)
* [Github - Adrenine](https://github.com/Adrenine)
