//
//  DKPromise+Always.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^DKPromiseAlwaysBlock)(void);

@interface DKPromise (Always)

-(DKPromise *)always:(DKPromiseAlwaysBlock)work;

-(DKPromise *)onQueue:(dispatch_queue_t)queue
               always:(DKPromiseAlwaysBlock)work;

@end

NS_ASSUME_NONNULL_END
