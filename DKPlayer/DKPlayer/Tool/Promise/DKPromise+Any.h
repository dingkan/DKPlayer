//
//  DKPromise+Any.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "DKPromise.h"

NS_ASSUME_NONNULL_BEGIN

@interface DKPromise (Any)

-(DKPromise <NSArray *>*)any:(NSArray *)promises;

-(DKPromise <NSArray *>*)onQueue:(dispatch_queue_t)queue
                             any:(NSArray *)promises;

@end

NS_ASSUME_NONNULL_END
