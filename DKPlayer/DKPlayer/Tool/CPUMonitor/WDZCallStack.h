//
//  WDZCallStack.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/9.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//  栈

#import <Foundation/Foundation.h>
#import "WDZCallLib.h"

typedef enum : NSUInteger {
    kWDZStackTypeAll,
    kWDZStackTypeMain,
    kWDZStackTypeCurrent,
} kWDZStackType;

NS_ASSUME_NONNULL_BEGIN

@interface WDZCallStack : NSObject

+(NSString *)callStackWithType:(kWDZStackType)type;

extern NSString *wdzStackOfThread(thread_t thread);

@end

NS_ASSUME_NONNULL_END
