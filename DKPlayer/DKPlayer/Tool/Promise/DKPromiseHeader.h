//
//  DKPromiseHeader.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/8/20.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#ifndef DKPromiseHeader_h
#define DKPromiseHeader_h

typedef enum : NSUInteger {
    DKPromiseStatePending = 0,
    DKPromiseStateFulfilled,
    DKPromiseStateRejected,
} DKPromiseState;

#endif /* DKPromiseHeader_h */
