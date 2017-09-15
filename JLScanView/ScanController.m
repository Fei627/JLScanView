//
//  ScanController.m
//  JLScanView
//
//  Created by gaojianlong on 2017/9/14.
//  Copyright © 2017年 JLB. All rights reserved.
//

#import "ScanController.h"
#import "JLWebController.h"
#import <AVFoundation/AVFoundation.h>

#define kScan_X         20
#define kScan_Y         100
#define kScan_W         (self.view.bounds.size.width - (kScan_X * 2))
#define kScan_H         200

@interface ScanController () <AVCaptureMetadataOutputObjectsDelegate>

/**
 没有相机权限的提示视图
 */
@property (nonatomic, strong) UIView *errorView;

/**
 扫描线
 */
@property (nonatomic, strong) UIView *scanLine;

/**
 创建相机AVCaptureDevice
 AVCaptureDevice的每个实例对应一个设备,如摄像头或麦克风.
 */
@property (nonatomic, strong) AVCaptureDevice *device;

/**
 创建输入设备AVCaptureDeviceInput
 AVCaptureDeviceInput是AVCaptureInput子类提供一个接口,用于捕获从一个AVCaptureDevice媒体。
 AVCaptureDeviceInput是AVCaptureSession实例的输入源,提供媒体数据从设备连接到系统.
 */
@property (nonatomic, strong) AVCaptureDeviceInput *input;

/**
 创建输出设备AVCaptureMetadataOutput
 
 */
@property (nonatomic, strong) AVCaptureMetadataOutput *output;

/**
 创建AVFoundation中央枢纽捕获类AVCaptureSession
 */
@property (nonatomic, strong) AVCaptureSession *session;

/**
 创建AVCaptureSession预览视觉输出AVCaptureVideoPreviewLayer
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preview;

@end

@implementation ScanController

#pragma mark - 生命周期

- (void)dealloc
{
    self.scanDelegate = nil;
    [_session removeObserver:self forKeyPath:@"running" context:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (![_session isRunning]) {
        [_session startRunning];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"扫描";
    
    [self initCamera];
}

#pragma mark - 初始化设备

- (void)initCamera
{
    // 初始化基础"引擎"Device
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 初始化输入流 Input,并添加Device
    NSError *error;
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    NSLog(@"error：%@",error);
 
    // 初始化输出流Output
    _output = [[AVCaptureMetadataOutput alloc] init];
    
    // 创建view,通过layer层进行设置边框宽度和颜色,用来辅助展示扫描的区域
    UIView *scanArea = [[UIView alloc] initWithFrame:CGRectMake(kScan_X, kScan_Y, kScan_W, kScan_H)];
    scanArea.layer.borderWidth = 2;
    scanArea.layer.borderColor = [UIColor cyanColor].CGColor;
    [self.view addSubview:scanArea];
    
    [scanArea addSubview:self.scanLine];
    _scanLine.frame = CGRectMake(1, 0, kScan_W - 2, 0.5);
    
    // 设置输出流的相关属性
    // 确定输出流的代理和所在的线程,这里代理遵循的就是上面我们在准备工作中提到的第一个代理
    // 至于线程的选择,建议选在主线程,这样方便当前页面对数据的捕获.
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    
    CGSize size = self.view.bounds.size;
    CGFloat x = kScan_Y / size.height;
    CGFloat y = (size.width - kScan_X - kScan_W) / size.width;
    CGFloat w = kScan_H / size.height;
    CGFloat h = kScan_W / size.width;
    _output.rectOfInterest = CGRectMake(x, y, w, h);
    
    // 初始化捕获数据类AVCaptureSession
    
    // 初始化session
    _session = [[AVCaptureSession alloc] init];
    
    // 设置session类型,AVCaptureSessionPresetHigh 是 sessionPreset 的默认值。
    [_session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    
    // 将输入流和输出流添加到session中
    
    // 添加输入流
    if ([_session canAddInput:_input]) {
        [_session addInput:_input];
    }
    
    // 添加输出流
    if ([_session canAddOutput:_output]) {
        [_session addOutput:_output];
    }
    
    // 下面的是比较重要的,也是最容易出现崩溃的原因,就是我们的输出流的类型
    // 1.这里可以设置多种输出类型,这里必须要保证session层包括输出流
    // 2.必须要当前项目访问相机权限必须通过,所以最好在程序进入当前页面的时候进行一次权限访问的判断
    _output.metadataObjectTypes = @[AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeCode128Code,AVMetadataObjectTypeCode39Mod43Code,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode93Code,AVMetadataObjectTypeQRCode];
    
    // 设置输出展示平台AVCaptureVideoPreviewLayer
    
    // 初始化
    _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    
    // 设置Video Gravity,顾名思义就是视频播放时的拉伸方式,默认是AVLayerVideoGravityResizeAspect
    // AVLayerVideoGravityResizeAspect 保持视频的宽高比并使播放内容自动适应播放窗口的大小。
    // AVLayerVideoGravityResizeAspectFill 和前者类似，但它是以播放内容填充而不是适应播放窗口的大小。最后一个值会拉伸播放内容以适应播放窗口.
    // 因为考虑到全屏显示以及设备自适应,这里我们采用fill填充
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    // 设置展示平台的frame
    _preview.frame = CGRectMake(0, 0, size.width, size.height);
    
    // 因为 AVCaptureVideoPreviewLayer是继承CALayer,所以添加到当前view的layer层
    [self.view.layer insertSublayer:_preview atIndex:0];
 
    // 监听扫码运行状态
    [_session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:nil];
    
    // 一切准备就绪,开始运行
    [_session startRunning];
}

#pragma mark - KVO（监听扫描状态,修改扫描动画）

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    if ([object isKindOfClass:[AVCaptureSession class]]) {
        BOOL isRunning = [(AVCaptureSession *)object isRunning];
        if (isRunning) {
            [self beginAnimation];
        } else {
            [_scanLine.layer removeAllAnimations];
        }
    }
}

- (void)beginAnimation
{
    _scanLine.frame = CGRectMake(1, 0, kScan_W - 2, 0.5);
    [UIView animateWithDuration:3 animations:^{
        _scanLine.frame = CGRectMake(1, kScan_H, kScan_W - 2, 0.5);
    } completion:^(BOOL finished) {
        if (finished) {
            [self beginAnimation];
        }
    }];
}

#pragma mark - 处理扫描结果

#pragma mark AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    // 判断扫描结果的数据是否存在
    if ([metadataObjects count] > 0) {
        
        // 如果存在数据,停止扫描
        [_session stopRunning];
        
        // AVMetadataMachineReadableCodeObject是AVMetadataObject的具体子类定义的特性检测一维或二维条形码。
        // AVMetadataMachineReadableCodeObject代表一个单一的照片中发现机器可读的代码。这是一个不可变对象描述条码的特性和载荷。
        // 在支持的平台上,AVCaptureMetadataOutput输出检测机器可读的代码对象的数组
        AVMetadataMachineReadableCodeObject *metadaObject = [metadataObjects objectAtIndex:0];
        
        // 获取扫描到的信息
        NSString *stringValue = metadaObject.stringValue;
        
        if (self.scanDelegate && [self.scanDelegate respondsToSelector:@selector(scanResultWithArray:)]) {
            [self.scanDelegate scanResultWithArray:metadataObjects];
            [self.scanDelegate scanResultWithString:stringValue];
        }
        
        // 处理扫描结果
        //[self analyzeScanResult:stringValue];
        
    } else {
        NSLog(@" ----扫描错误---- ");
    }
}

#pragma mark - 扩展方法（根据实际需求，选择使用）

// 判断扫描结果类型做相应跳转
- (void)analyzeScanResult:(NSString *)resultString
{
    if ([resultString containsString:@"http://"] || [resultString containsString:@"https://"]) {
        JLWebController *vc = [[JLWebController alloc] init];
        vc.webUrl = resultString;
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"扫描结果"
                                                                       message:resultString
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           //开始扫描
                                                           [_session startRunning];
                                                       }];
        
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

// 判断相机权限
- (BOOL)isHaveCameraPermission
{
    // 读取设备授权状态
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if(authStatus == AVAuthorizationStatusNotDetermined || authStatus == AVAuthorizationStatusDenied || authStatus == AVAuthorizationStatusRestricted) {
        return NO;
    }
    
    return YES;
}

// 展示请求相机权限弹窗
- (void)showCameraPermissionView
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"项目名称"
                                                                   message:@"请在iPhone的“设置”-“隐私”-“相机”功能中，找到“项目名称”打开相机访问权限"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    __weak typeof(self) weakSelf = self;
    UIAlertAction *action_set = [UIAlertAction actionWithTitle:@"前往设置"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           
                                                           [weakSelf popSystemSetView];
                                                       }];
    
    UIAlertAction *action_ok = [UIAlertAction actionWithTitle:@"稍后设置"
                                                        style:UIAlertActionStyleDefault
                                                      handler:nil];
    
    [alert addAction:action_set];
    [alert addAction:action_ok];
    [self presentViewController:alert animated:YES completion:nil];
}

// 跳转系统设置界面
- (void)popSystemSetView
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
}

#pragma mark - 公共接口

- (void)startScan
{
    [_session startRunning];
}

- (void)stopScan
{
    [_session stopRunning];
}

- (void)back
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - setter && getter

- (UIView *)errorView
{
    if (!_errorView) {
        _errorView = [[UIView alloc] initWithFrame:self.view.frame];
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(20, 84, kScreen_Width - 40, 20);
        label.text = @"请前往“系统设置”打开“隐私”，允许使用相机权限";
        [_errorView addSubview:label];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(20, CGRectGetMaxY(label.frame) + 10, CGRectGetWidth(label.frame), 20);
        [btn setTitle:@"前往设置" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(popSystemSetView) forControlEvents:UIControlEventTouchUpInside];
        [_errorView addSubview:btn];
    }
    return _errorView;
}

- (UIView *)scanLine
{
    if (!_scanLine) {
        _scanLine = [[UIView alloc] init];
        _scanLine.backgroundColor = [UIColor cyanColor];
    }
    return _scanLine;
}

@end
