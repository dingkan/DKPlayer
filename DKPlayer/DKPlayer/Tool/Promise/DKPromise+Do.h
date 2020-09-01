//
//  DKPromise+Do.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise.h"

NS_ASSUME_NONNULL_BEGIN

typedef id __nullable (^DKPromiseDoBlock)(void);

@interface DKPromise (Do)

-(DKPromise *)do:(DKPromiseDoBlock)work;

-(DKPromise *)onQueue:(dispatch_queue_t)queue do:(DKPromiseDoBlock)work;

@end

NS_ASSUME_NONNULL_END
