//
//  dkSDK_gles2.h
//  DKPlayer
//
//  Created by 丁侃 on 2020/12/29.
//  Copyright © 2020 丁侃. All rights reserved.
//

#ifndef dkSDK_gles2_h
#define dkSDK_gles2_h

#ifdef __APPLE__
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#else
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <GLES2/gl2platform.h>
#endif

#endif /* dkSDK_gles2_h */
