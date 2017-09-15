//
//  ViewController.m
//  JLScanView
//
//  Created by gaojianlong on 2017/9/14.
//  Copyright © 2017年 JLB. All rights reserved.
//

#import "ViewController.h"
#import "ScanController.h"
#import "JLWebController.h"

@interface ViewController () <ScanResultDelegate>

@property (nonatomic, strong) UIBarButtonItem *rightButton;

@property (nonatomic, strong) ScanController *scanVC;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"首页";
    self.navigationItem.rightBarButtonItem = self.rightButton;
}

- (void)scanAction
{
    self.scanVC = [[ScanController alloc] init];
    self.scanVC.scanDelegate = self;
    [self.navigationController pushViewController:self.scanVC animated:YES];
}

#pragma mark - ScanResultDelegate

- (void)scanResultWithString:(NSString *)string
{
    NSLog(@"回调结果字符串：%@",string);
    [self analyzeScanResult:string];
}

- (void)scanResultWithArray:(NSArray *)array
{
    NSLog(@"回调结果源数据：%@",array);
}

#pragma mark - 处理回调的扫描结果（可根据需求自定义）

- (void)analyzeScanResult:(NSString *)resultString
{
    __weak typeof(self) weakSelf = self;
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
                                                           [weakSelf.scanVC back];
                                                       }];
        
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

/*
- (void)removeCurrentScanView
{// 压栈
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    for (UIViewController *tempVC in tempArray) {
        if ([tempVC isKindOfClass:[ScanController class]]) {
            [tempArray removeObject:tempVC];
            break;
        }
    }
    self.navigationController.viewControllers = tempArray;
}
*/

- (UIBarButtonItem *)rightButton
{
    if (!_rightButton) {
        _rightButton = [[UIBarButtonItem alloc] initWithTitle:@"扫描"
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(scanAction)];
    }
    return _rightButton;
}

@end
