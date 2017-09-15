//
//  ScanController.h
//  JLScanView
//
//  Created by gaojianlong on 2017/9/14.
//  Copyright © 2017年 JLB. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ScanResultDelegate <NSObject>

@optional

// 扫描成功，源数据(PS:使用此协议方法，需要在当前类中，自己导入<AVFoundation/AVFoundation.h>框架)
- (void)scanResultWithArray:(NSArray *)array;

// 扫描成功，解析后的字符串
- (void)scanResultWithString:(NSString *)string;

@end

@interface ScanController : UIViewController

@property (nonatomic , assign) id scanDelegate;

- (void)startScan;
- (void)stopScan;
- (void)back;

@end
