//
//  DKSDLGLView.h
//  DKPlayer
//
//  Created by 丁侃 on 2020/12/29.
//  Copyright © 2020 丁侃. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DKSDLGLViewPortocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DKSDLGLView : UIView<DKSDLGLViewPortocol>

-(id)initWithFrame:(CGRect)frame;

-(void)display_pixels:(DKOverlay *)overlay;

-(UIImage *)snapshot;


@end

NS_ASSUME_NONNULL_END
