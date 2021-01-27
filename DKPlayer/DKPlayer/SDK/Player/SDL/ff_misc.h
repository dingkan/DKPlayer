//
//  ff_misc.h
//  DKPlayer
//
//  Created by 丁侃 on 2021/1/27.
//  Copyright © 2021 丁侃. All rights reserved.
//

#ifndef ff_misc_h
#define ff_misc_h

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

inline static void *mallocz(size_t size)
{
    void *mem = malloc(size);
    if (!mem) {
        return mem;
    }
    
    memset(mem, 0, size);
    return mem;
}

inline static void freep(void **mem)
{
    if (mem && *mem) {
        free(*mem);
        *mem = NULL;
    }
}

#endif /* ff_misc_h */
