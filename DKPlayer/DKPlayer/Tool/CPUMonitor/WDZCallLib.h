//
//  WDZCallLib.h
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/9.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <mach/mach.h>
#include <dlfcn.h>
#include <pthread.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>

#include <mach/task.h>
#include <mach/vm_map.h>
#include <mach/mach_init.h>
#include <mach/thread_act.h>
#include <mach/thread_info.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/sysctl.h>
#include <objc/message.h>
#include <objc/runtime.h>
#include <dispatch/dispatch.h>

NS_ASSUME_NONNULL_BEGIN
// __LP64__ __arm64__ 这样的宏定义是在编译器里定义的。https://github.com/llvm-mirror/clang/blob/0e261f7c4df17c1432f9cc031ae12e3cf5a19347/lib/Frontend/InitPreprocessor.cpp

//mach_header_64 Mach-O文件 中的 header标题，指定文件的目标体结构


// struct segment_command_64 { /* for 64-bit architectures */
     //uint32_t    cmd;        /* LC_SEGMENT_64 */
     //uint32_t    cmdsize;    /* includes sizeof section_64 structs */
//     char        segname[16];    /* segment name */
//     uint64_t    vmaddr;        /* memory address of this segment */
//     uint64_t    vmsize;        /* memory size of this segment */
//     uint64_t    fileoff;    /* file offset of this segment */
//     uint64_t    filesize;    /* amount to map from the file */
//     vm_prot_t    maxprot;    /* maximum VM protection */
//     vm_prot_t    initprot;    /* initial VM protection */
//     uint32_t    nsects;        /* number of sections in segment */
//     uint32_t    flags;        /* flags */
// };
/**
 Load Commands 被看作一个command列表，紧贴着Header，由内核定义，不同版本的commadn数量不同
 描述了文件映射的两大问题
 从哪里来（fileoff、filesize）
 到哪里去（vmaddr、vmsize）
 内核该区域的名字（segname，即 segment name）
 该区域包含了几个 section（nsects）
 该区域的保护级别（initprot、maxprot）
 */

//section_64 可以看作section header,它描述了对应section的具体位置，以及要被映射的目标虚拟地址

#ifdef __LP64__
typedef struct mach_header_64     machHeaderByCPU;
typedef struct segment_command_64 segmentComandByCPU;
typedef struct section_64         sectionByCPU;
typedef struct nlist_64           nlistByCPU;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64

#else
typedef struct mach_header        machHeaderByCPU;
typedef struct segment_command    segmentComandByCPU;
typedef struct section            sectionByCPU;
typedef struct nlist              nlistByCPU;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT
#endif

#ifndef SEG_DATA_CONST
#define SEG_DATA_CONST  "__DATA_CONST"
#endif
@interface WDZCallLib : NSObject

@end

NS_ASSUME_NONNULL_END
