//
//  WDZCallStackModel.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/9.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WDZCallStackModel : NSObject

@property (nonatomic, copy) NSString *stackStr;

@property (nonatomic) BOOL isStuck;

@property (nonatomic, assign) NSTimeInterval dateString;

@end

NS_ASSUME_NONNULL_END
