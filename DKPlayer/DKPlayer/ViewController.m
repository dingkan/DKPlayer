//
//  ViewController.m
//  DKPlayer
//
//  Created by 丁侃 on 2020/8/31.
//  Copyright © 2020 丁侃. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa.h>
#import "WDZClsCallViewController.h"
#import "WDZStackViewController.h"
#import "WDZLagMonitor.h"

@interface ViewController ()
@property (nonatomic, strong) UIButton *stackBt;
@property (nonatomic, strong) UIButton *clsCallBt;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.stackBt];
    [self.view addSubview:self.clsCallBt];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[WDZLagMonitor shareInstance] beginMonitor];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[WDZLagMonitor shareInstance] endMonitor];
}

- (UIButton *)stackBt {
    if (!_stackBt) {
        
        _stackBt = [UIButton buttonWithType:UIButtonTypeCustom];
        _stackBt.frame = CGRectMake(100, 100, 50, 44);
        [_stackBt setTitle:@"堆栈" forState:UIControlStateNormal];
        _stackBt.titleLabel.font = [UIFont systemFontOfSize:16];
        [_stackBt setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        
        typeof(self)wself = self;
        
        [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [[wself.stackBt rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
                [subscriber sendNext:@"click"];
            }];
            return nil;
        }] subscribeNext:^(id x) {
            typeof(self) strongSelf = wself;
            
            WDZStackViewController *vc = [[WDZStackViewController alloc] init];
            [strongSelf presentViewController:vc animated:YES completion:nil];
        }];
    }
    return _stackBt;
}
- (UIButton *)clsCallBt {
    if (!_clsCallBt) {
        _clsCallBt = [UIButton buttonWithType:UIButtonTypeCustom];
        [_clsCallBt setTitle:@"频次" forState:UIControlStateNormal];
        _clsCallBt.titleLabel.font = [UIFont systemFontOfSize:16];
        [_clsCallBt setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        
        _clsCallBt.frame = CGRectMake(150, 100, 50, 44);
        
        typeof(self)wself = self;
        
        [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [[wself.clsCallBt rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
                [subscriber sendNext:@"click"];
            }];
            return nil;
        }] subscribeNext:^(id x) {
            typeof(self) strongSelf = wself;
            WDZClsCallViewController *vc = [[WDZClsCallViewController alloc] init];
            [strongSelf presentViewController:vc animated:YES completion:nil];
        }];
    }
    return _clsCallBt;
}

@end
