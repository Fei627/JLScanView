//
//  JLWebController.m
//  JLScanView
//
//  Created by gaojianlong on 2017/9/15.
//  Copyright © 2017年 JLB. All rights reserved.
//

#import "JLWebController.h"

@interface JLWebController ()

@property (nonatomic, strong) UIWebView *web;

@end

@implementation JLWebController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.web];
    
    if (self.webUrl) {
        [self.web loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.webUrl]]];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (UIWebView *)web
{
    if (!_web) {
        _web = [[UIWebView alloc] init];
        _web.frame = self.view.frame;
        _web.scrollView.bounces = NO;
        _web.scrollView.showsVerticalScrollIndicator = NO;
    }
    return _web;
}

@end
