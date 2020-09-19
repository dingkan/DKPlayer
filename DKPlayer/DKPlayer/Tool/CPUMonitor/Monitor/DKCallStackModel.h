//
//  DKCallStackModel.h
//  DKPlayer
//
//  Created by 丁侃 on 2020/9/15.
//  Copyright © 2020 丁侃. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DKCallStackModel : NSObject
@property (nonatomic, copy) NSString *stackStr;//完整的堆栈信息
@property (nonatomic) BOOL isStuck;
@property (nonatomic, assign) NSTimeInterval dateString;//可展示信息
@end

NS_ASSUME_NONNULL_END
