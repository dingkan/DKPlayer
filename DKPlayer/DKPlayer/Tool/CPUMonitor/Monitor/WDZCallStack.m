//
//  WDZCallStack.m
//  WDZForAppStore
//
//  Created by 丁侃 on 2020/9/9.
//  Copyright © 2020 Wandianzhang. All rights reserved.
//

#import "WDZCallStack.h"

//栈帧
//uintptr_t 类型用来存放指针地址
typedef struct WDZStackFrame{
    const struct WDZStackFrame *const previous;
    const uintptr_t return_address;
}WDZStackFrame;

//thread info
typedef struct WDZThreadInfoFrame{
    double cpuUsage;
    integer_t userTime;
}WDZThreadInfoFrame;

static mach_port_t _wdzMainThreadId;

@implementation WDZCallStack

+(void)load{
    //获得线程内核端口的发送权限
    _wdzMainThreadId = mach_thread_self();
}

//获取对应线程信息
+(NSString *)callStackWithType:(kWDZStackType)type{
    
    if (type == kWDZStackTypeAll) {
        
        thread_act_array_t list;
        mach_msg_type_number_t listCnt = 0;
        const task_t task = mach_thread_self();//init
        //获取这个task 所有线程
        kern_return_t kt = task_threads(task, &list, &listCnt);
        if (kt != KERN_SUCCESS) {
            return @"fail get all threads";
        }
        
        NSMutableString *reStr = [NSMutableString stringWithFormat:@"Call %u threads:\n",listCnt];
        for (int i = 0; i < listCnt; i ++) {
            //当前执行的指令
            [reStr appendString:wdzStackOfThread(list[i])];
        }
        //task info
        NSString *memStr = @"";
        struct mach_task_basic_info taskBasicInfo;
        mach_msg_type_number_t taskInfoCount = sizeof(taskBasicInfo) / sizeof(integer_t);
        if (task_info(task, MACH_TASK_BASIC_INFO, (task_info_t)&taskBasicInfo, &taskInfoCount) == KERN_SUCCESS) {
            memStr = [NSString stringWithFormat:@"used %llu MB \n",taskBasicInfo.resident_size / (1024 * 1024)];
        }
        NSLog(@"%@%@",memStr, reStr);
        
        //释放虚拟缓存，防止leak
        assert(vm_deallocate(task, (vm_address_t)list, listCnt * sizeof(thread_t)) == KERN_SUCCESS);
        return [reStr copy];
        
    }else if (type == kWDZStackTypeMain){
        NSString *reStr = wdzStackOfThread((thread_t)_wdzMainThreadId);
        assert(vm_deallocate(mach_thread_self(), (vm_address_t)_wdzMainThreadId, 1 * sizeof(thread_t)) == KERN_SUCCESS);
        NSLog(@"%@",reStr);
        return [reStr copy];
    }else if (type == kWDZStackTypeCurrent){
        //当前线程
        char name[256];
        mach_msg_type_number_t count;
        thread_act_array_t list;
        //根据当前task获取所有线程
        task_threads(mach_thread_self(), &list, &count);
        NSTimeInterval currentTimeStamp = [[NSDate date] timeIntervalSince1970];
        NSThread *nsthread = [NSThread currentThread];
        NSString *originName = nsthread.name;
        [nsthread setName:[NSString stringWithFormat:@"%f",currentTimeStamp]];
        NSString *resStr = @"";
        
        for (int i = 0; i < count; i ++) {
            //thread 与 pthread相互转换接口
            pthread_t pt = pthread_from_mach_thread_np(list[i]);
            
            if (pt) {
                name[0] = '\0';
                pthread_getname_np(pt, name, sizeof name);
                //is current
                if (!strcmp(name, [nsthread name].UTF8String)) {
                    [nsthread setName:originName];
                    resStr = wdzStackOfThread(list[i]);
                    assert(vm_deallocate(mach_thread_self(), (vm_address_t)list[i], 1 * sizeof(thread_t)) == KERN_SUCCESS);
                    NSLog(@"%@",resStr);
                    return [resStr copy];
                }
            }
            
        }
        
        [nsthread setName:originName];
        resStr = wdzStackOfThread(mach_thread_self());
        NSLog(@"%@",resStr);
        return [resStr copy];
    }return @"";
}

#pragma mark get stack of mach_thread
//当前栈帧结构
NSString *wdzStackOfThread(thread_t thread){
    WDZThreadInfoFrame threadInfoSt = {0};
    
    thread_info_data_t threadInfo;
    thread_basic_info_t threadBasicInfo;
    mach_msg_type_number_t threadInfoCount = THREAD_INFO_MAX;
    
    //获取线程堆栈数据
    if (thread_info((thread_inspect_t) thread, THREAD_BASIC_INFO, (thread_info_t)threadInfo, &threadInfoCount) == KERN_SUCCESS) {
        threadBasicInfo = (thread_basic_info_t)threadInfo;
        if (!(threadBasicInfo->flags & TH_FLAGS_IDLE)) {//非空闲线程
            //存储自定义线程信息
            threadInfoSt.cpuUsage = threadBasicInfo->cpu_usage / 10;
            threadInfoSt.userTime = threadBasicInfo->system_time.microseconds;
        }
    }
    
    uintptr_t buffer[100];
    int i = 0;
    NSMutableString *reStr = [NSMutableString stringWithFormat:@"Stack of thread :%u:\nCPU used: %1.f percent\nuser time:%d second\n",thread, threadInfoSt.cpuUsage,threadInfoSt.userTime];
    
    //线程栈里所有的栈指针
    _STRUCT_MCONTEXT machineContext;
    //通过thread_get_state 获取完整的 machineContext信息，包括thread 状态信息
    mach_msg_type_number_t state_count = wdzThreadStateCountByCPU();
    //对于每一个线程，可以用 thread_get_state 方法获取他的所有信息，信息填充在_STRUCT_MCONTEXT 类型的参数中
    kern_return_t kr = thread_get_state(thread, wdzThreadStateByCPU(), (thread_state_t)&machineContext.__ss, &state_count);
    if (kr != KERN_SUCCESS) {
        return [NSString stringWithFormat:@"Fail get thread: %u",thread];
    }
    
    //通过指令指针获取当前指令地址
    const uintptr_t instructionAddress = wdzMachStackBasePointerByCPU(&machineContext);
    buffer[i] = instructionAddress;
    ++i;
    
    uintptr_t linkRegisterPointer = wdzMachThreadGetLinkRegisterPointerByCPU(&machineContext);
    if (linkRegisterPointer) {
        buffer[i] = linkRegisterPointer;
        i ++;
    }
    
    if (instructionAddress == 0) {
        return @"Fail to get instruction address";
    }
    
    //自定义栈帧
    WDZStackFrame stackFrame = {0};
    //通过栈地址指针获取当前栈帧地址
    const uintptr_t framePointer = wdzMachStackBasePointerByCPU(&machineContext);
    if (framePointer == 0 || wdzMemCopySafely((void *)framePointer, &stackFrame, sizeof(stackFrame)) != KERN_SUCCESS) {
        return @"Fail frame pointer";
    }
    
    for (; i < 32; i ++) {
        buffer[i] = stackFrame.return_address;
        if (buffer[i] == 0 || stackFrame.previous == 0 || wdzMemCopySafely(stackFrame.previous, &stackFrame, sizeof(stackFrame)) != KERN_SUCCESS) {
            break;
        }
    }
    
    //处理dlsym,对地址进行符号化解析
    /**
     1.找到地址所属的内存镜像
     2.定位镜像中的符号表
     3.在符号表中找到目标地址的符号
     */
    int stackLength = i;
    //DL_info 用来保存解析的结果
    Dl_info symbolicated[stackLength];
    wdzSymbolicate(buffer, symbolicated, stackLength, 0);
    for (int i = 0; i < stackLength; ++i) {
        [reStr appendFormat:@"%@",wdzOutputLog(i, buffer[i], &symbolicated[i])];
    }
    [reStr appendFormat:@"\n"];
    return reStr;
}

#pragma mark - buildStack
NSString *wdzOutputLog(const int entryNum, const uintptr_t address, const Dl_info* const dlInfo){
    const char* name = dlInfo->dli_fname;
    if (name == NULL) {
        return @"";
    }
    //获取路径最后文件名
    char *lastFile = strrchr(dlInfo->dli_fname, '/');
    NSString *fName = @"";
    if (lastFile == NULL) {
        fName = [NSString stringWithFormat:@"%-30s",name];
    }else{
        fName = [NSString stringWithFormat:@"%-30s",lastFile + 1];
    }
    
    uintptr_t offset = address - (uintptr_t)dlInfo->dli_saddr;
    const char * sname = dlInfo->dli_sname;
    if (sname == NULL) {
        return @"";
    }else{
        return [NSString stringWithFormat:@"%@ 0x%08" PRIxPTR " %s + %lu\n",fName, (uintptr_t)address, sname, offset];
    }
}

#pragma mark -MachineContext
kern_return_t wdzMemCopySafely(const void *const src, void *const dst, const size_t byteSize){
    vm_size_t byteCopied = 0;
    //根据栈帧指针获取对应的函数地址
    return vm_read_overwrite(mach_task_self(), (vm_address_t)src, (vm_size_t)byteSize, (vm_address_t)dst, &byteCopied);
}

#pragma mark - Symbolicate
void wdzSymbolicate(const uintptr_t *const stackBuffer, Dl_info *const symbolsBuffer, const int stackLength, const int skippedEntries){
    int i = 0;
    if (!skippedEntries && i < stackLength) {
        wdzDladdr(stackBuffer[i], &symbolsBuffer[i]);
        i ++;
    }
    for (; i < stackLength; i ++) {
        wdzDladdr(wdzInstructionAddressByCPU(stackBuffer[i]), &symbolsBuffer[i]);
    }
}

bool wdzDladdr(const uintptr_t address, Dl_info* const info){
    info->dli_fname = NULL;
    info->dli_fbase = NULL;
    info->dli_sname = NULL;
    info->dli_fbase = NULL;
    
    //更具地址获取对应的image
    const uint32_t idx = wdzDyldImageIndexFromAddress(address);
    if (idx == UINT_MAX) {
        return false;
    }
    
    /*
     Header
     ------------------
     Load commands
     Segment command 1 -------------|
     Segment command 2              |
     ------------------             |
     Data                           |
     Section 1 data |segment 1 <----|
     Section 2 data |          <----|
     Section 3 data |          <----|
     Section 4 data |segment 2
     Section 5 data |
     ...            |
     Section n data |
     */
    
    /*---------  Mach Header  ----------*/
    //根据image序号获取mach_header
    const struct mach_header* machHeader = _dyld_get_image_header(idx);
    
    //获取镜像的虚拟内存地址slider的数量
    //动态连接器加载image时， image必须映射到未占用地址的进程的虚拟地址空间，动态连接器通过添加一个值带 image的基地址来实现，这个值就是虚拟内存slider数量
    const uintptr_t imageVMAddressSlide = (uintptr_t)_dyld_get_image_vmaddr_slide(idx);
    
    
    /*---------  ASLR 偏移量  ----------*/
    const uintptr_t addressWithSlide = address - imageVMAddressSlide;
    //根据image的index 获取segment的地址
    //段定义Mach-O文件中的字节范围以及动态链接器加载应用程序时这些字节映射到虚拟内存中的地址和内存保护属性。 因此，段总是虚拟内存页对齐。 片段包含零个或多个节。
    const uintptr_t segmentBase = wdzSegmentBaseOfImageIndex(idx) + imageVMAddressSlide;
    
    if (segmentBase == 0) {
        return false;
    }
    
    info->dli_fname = _dyld_get_image_name(idx);
    info->dli_fbase = (void *)machHeader;
    
    
    /*---------  Mach segment  ----------*/
    //地址最匹配的symbol
    const nlistByCPU* bestMatch = NULL;
    uintptr_t bestDistance = ULONG_MAX;
    uintptr_t cmdPointer = wdzCmdFirstPointerFromMachHeader(machHeader);
    if (cmdPointer == 0) {
        return false;
    }
    
    //遍历每个segment 判断目标地址是否落在该 segment包含的范围里
    for (uint32_t iCmd = 0; iCmd < machHeader->ncmds; iCmd ++) {
        const struct load_command *loadCmd = (struct load_command *)cmdPointer;

        /*---------  目标  image 的符号表  ----------*/
        //segment 除了__TEXT 和 __DATA 外还有 __LINKEDIT segment, 它里面包含动态连接器的使用的原始数据，比如符号，字符串和重定位表象
        //LC_SYMTAB 描述了 __LINKEDIT segment 内查找字符串和符号表的位置
        if (loadCmd->cmd == LC_SYMTAB) {
            //获取字符串和符号表的虚拟内存偏移量
            const struct symtab_command* symtabCmd = (struct symtab_command *)cmdPointer;
            const nlistByCPU* symbolTable = (nlistByCPU*)(segmentBase + symtabCmd->symoff);
            const uintptr_t stringTable = segmentBase + symtabCmd->stroff;
            
            for (uint32_t iSym = 0; iSym < symtabCmd->nsyms; iSym++) {
                //如果 n_value 是0， symbol指向外部对象
                if (symbolTable[iSym].n_value != 0) {
                    //给定的偏移量是文件偏移量，减去 __LINKEDIT segment 的文件偏移量获得字符串和符号表的虚拟内存偏移量
                    uintptr_t symbolBase = symbolTable[iSym].n_value;
                    uintptr_t currentDistance = addressWithSlide - symbolBase;
                    //寻找最小的距离 bestDistance, 因为addressWithSlide是某个方法的指令地址，要大于这个方法的入口。
                    //离 addressWithSilde越近的函数入口越匹配
                    if ((addressWithSlide >= symbolBase) && (currentDistance <= bestDistance)) {
                        bestMatch = symbolTable + iSym;
                        bestDistance = currentDistance;
                    }
                }
            }
            
            if (bestMatch != NULL) {
                //将虚拟内存偏移量添加到 __LINKEDIT segment 的虚拟内存地址可以提供字符串和符号表的内存 address
                info->dli_saddr = (void *)(bestMatch->n_value + imageVMAddressSlide);
                info->dli_sname = (char *)((intptr_t)stringTable + (intptr_t)bestMatch->n_un.n_strx);
                if (*info->dli_sname == '_') {
                    info->dli_sname++;
                }
                //所有的 symbols 的已经被处理好了
                if (info->dli_saddr == info->dli_fbase && bestMatch->n_type == 3) {
                    info->dli_sname = NULL;
                }
                break;
            }
        }
        cmdPointer += loadCmd->cmdsize;
    }
    
    return true;
    
}

//通过address 找到对应的image的坐标，从而能够得到image的更多信息
uint32_t wdzDyldImageIndexFromAddress(const uintptr_t address){
    //返回当前image数，这里image不是线程安全的，因为另一个线程可能在处于添加或删除image期间
    const uint32_t imageCount = _dyld_image_count();
    const struct mach_header* machHeader = 0;
    //O(n2)的方式查找
    for (uint32_t iImg = 0; iImg < imageCount; iImg ++) {
        //返回一个指向由 image_index索引的 image 的 mach头的指针，如果 image_index超出范围，那么Null
        machHeader = _dyld_get_image_header(iImg);
        if (machHeader != NULL) {
            //查找 segment command
            //获取目标image的slide用来换算基址。不同的mach-o的slide不同
            uintptr_t addressWSild = address - (uintptr_t)_dyld_get_image_vmaddr_slide(iImg);
            uintptr_t cmdPoint = wdzCmdFirstPointerFromMachHeader(machHeader);
            if (cmdPoint == 0) {
                continue;
            }
            
            for (uint32_t iCmd = 0; iCmd < machHeader->ncmds; iCmd++) {
                const struct load_command *loadCmd = (struct load_command *)cmdPoint;
                //遍历mach header里的load commad时判断segment command 是32位还是64位，大部分系统segment都是32位的
                if (loadCmd->cmd == LC_SEGMENT) {
                    const struct segment_command* segCmd = (struct segment_command*)cmdPoint;
                    if (addressWSild >= segCmd->vmaddr && addressWSild < segCmd->vmaddr + segCmd->vmsize) {
                        return iImg;
                    }
                }else if (loadCmd->cmd == LC_SEGMENT_64){
                    const struct segment_command_64 *segCmd = (struct segment_command_64*)cmdPoint;
                    if (addressWSild >= segCmd->vmaddr && addressWSild < segCmd->vmaddr + segCmd->vmsize) {
                        return iImg;
                    }
                }
                
                cmdPoint += loadCmd->cmdsize;
            }
            
        }
    }
    
    return UID_MAX;
}

uintptr_t wdzCmdFirstPointerFromMachHeader(const struct mach_header* const machHeader){
    switch (machHeader->magic) {
        case MH_MAGIC:
        case MH_CIGAM:
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            return (uintptr_t)((machHeaderByCPU *)machHeader + 1);
            break;
        default:
            return 0;//Header 不合法
            break;
    }
}

uintptr_t wdzSegmentBaseOfImageIndex(const uint32_t ids){
    const struct mach_header *machHeader = _dyld_get_image_header(ids);
    //查找 segment commad 返回 image 地址
    uintptr_t cmdPtr = wdzCmdFirstPointerFromMachHeader(machHeader);
    if (cmdPtr == 0) {
        return 0;
    }
    
    for (uint32_t i = 0; i< machHeader->ncmds; i++) {
        const struct load_command *loadCmd = (struct load_command*)cmdPtr;
        const segmentComandByCPU* segmentCmd = (segmentComandByCPU*)cmdPtr;
        if (strcmp(segmentCmd->segname, SEG_LINKEDIT) == 0) {
            return (uintptr_t)(segmentCmd->vmaddr - segmentCmd->fileoff);
        }
        cmdPtr += loadCmd->cmdsize;
    }
    return 0;
}

#pragma mark - Deal with CPU seperate
/*
 //X86 for example
 SP/ESP/RSP: 栈顶部地址的栈指针
 BP/EBP/RBP: 栈基地址指针
 IP/EIP/RIP: 指令指针保留程序计数当前指令地址
 */
uintptr_t wdzMachStackBasePointerByCPU(mcontext_t const machineContext) {
    //Stack base pointer for holding the address of the current stack frame.
#if defined(__arm64__)
    return machineContext->__ss.__fp;
#elif defined(__arm__)
    return machineContext->__ss.__r[7];
#elif defined(__x86_64__)
    return machineContext->__ss.__rbp;
#elif defined(__i386__)
    return machineContext->__ss.__ebp;
#endif
}
uintptr_t wdzMachInstructionPointerByCPU(mcontext_t const machineContext) {
    //Instruction pointer. Holds the program counter, the current instruction address.
#if defined(__arm64__)
    return machineContext->__ss.__pc;
#elif defined(__arm__)
    return machineContext->__ss.__pc;
#elif defined(__x86_64__)
    return machineContext->__ss.__rip;
#elif defined(__i386__)
    return machineContext->__ss.__eip;
#endif
}
uintptr_t wdzInstructionAddressByCPU(const uintptr_t address) {
#if defined(__arm64__)
    const uintptr_t reAddress = ((address) & ~(3UL));
#elif defined(__arm__)
    const uintptr_t reAddress = ((address) & ~(1UL));
#elif defined(__x86_64__)
    const uintptr_t reAddress = (address);
#elif defined(__i386__)
    const uintptr_t reAddress = (address);
#endif
    return reAddress - 1;
}
mach_msg_type_number_t wdzThreadStateCountByCPU() {
#if defined(__arm64__)
    return ARM_THREAD_STATE64_COUNT;
#elif defined(__arm__)
    return ARM_THREAD_STATE_COUNT;
#elif defined(__x86_64__)
    return x86_THREAD_STATE64_COUNT;
#elif defined(__i386__)
    return x86_THREAD_STATE32_COUNT;
#endif
}
/*
 * target_thread 的执行状态，比如机器寄存器
 * THREAD_STATE_FLAVOR_LIST 0
 * these are the supported flavors
 #define x86_THREAD_STATE32      1
 #define x86_FLOAT_STATE32       2
 #define x86_EXCEPTION_STATE32   3
 #define x86_THREAD_STATE64      4
 #define x86_FLOAT_STATE64       5
 #define x86_EXCEPTION_STATE64   6
 #define x86_THREAD_STATE        7
 #define x86_FLOAT_STATE         8
 #define x86_EXCEPTION_STATE     9
 #define x86_DEBUG_STATE32       10
 #define x86_DEBUG_STATE64       11
 #define x86_DEBUG_STATE         12
 #define THREAD_STATE_NONE       13
 14 and 15 are used for the internal x86_SAVED_STATE flavours
 #define x86_AVX_STATE32         16
 #define x86_AVX_STATE64         17
 #define x86_AVX_STATE           18
*/
thread_state_flavor_t wdzThreadStateByCPU() {
#if defined(__arm64__)
    return ARM_THREAD_STATE64;
#elif defined(__arm__)
    return ARM_THREAD_STATE;
#elif defined(__x86_64__)
    return x86_THREAD_STATE64;
#elif defined(__i386__)
    return x86_THREAD_STATE32;
#endif
}
uintptr_t wdzMachThreadGetLinkRegisterPointerByCPU(mcontext_t const machineContext) {
#if defined(__i386__)
    return 0;
#elif defined(__x86_64__)
    return 0;
#else
    return machineContext->__ss.__lr;
#endif
}


@end