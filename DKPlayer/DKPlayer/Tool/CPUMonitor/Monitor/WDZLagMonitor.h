//
//  WDZLagMonitor.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/10.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//  检测卡顿

#import <Foundation/Foundation.h>
#import "WDZCallDB.h"

NS_ASSUME_NONNULL_BEGIN

@interface WDZLagMonitor : NSObject

@property (nonatomic, assign) BOOL isMonitoring;

+(instancetype)shareInstance;

-(void)beginMonitor;
-(void)endMonitor;

@end

NS_ASSUME_NONNULL_END
