//
//  WDZCallDB.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/9.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <FMDB.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>

#import "WDZCallStackModel.h"
#import "WDZCallTraceTimeCostModel.h"

#define PATH_OF_APP_HOME    NSHomeDirectory()
#define PATH_OF_TEMP        NSTemporaryDirectory()
#define PATH_OF_DOCUMENT    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

NS_ASSUME_NONNULL_BEGIN

@interface WDZCallDB : NSObject

+(instancetype)shareInstance;

#pragma stack
-(RACSignal *)increaseWithStackModel:(WDZCallStackModel *)model;
-(RACSignal *)selectStackWithPage:(NSUInteger)page;
-(void)clearStackData;

#pragma clsStack
-(void)addClsCallStackModel:(WDZCallTraceTimeCostModel *)model;
-(RACSignal *)selectClsCallStackWithPage:(NSUInteger)page;
-(void)clearClsCallStackData;


@end

NS_ASSUME_NONNULL_END
