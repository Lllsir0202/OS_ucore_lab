### lab4
#### 练习1：分配并初始化一个进程控制块（需要编码）

alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

    【提示】在alloc_proc函数的实现中，需要初始化的proc_struct结构中的成员变量至少包括：state/pid/runs/kstack/need_resched/parent/mm/context/tf/cr3/flags/name。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

    请说明proc_struct中struct context context和struct trapframe *tf成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

alloc_proc函数:
```C++
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
    proc->state = PROC_UNINIT;
    proc->pid = -1;
    proc->runs = 0;
    proc->kstack = 0;
    proc->need_resched = 0;
    proc->parent = NULL;
    proc->mm = NULL;
    memset(&(proc->context), 0, sizeof(struct context));
    proc->tf = NULL;
    proc->cr3 = boot_cr3;
    proc->flags = 0;
    memset(proc->name, 0, PROC_NAME_LEN);
    }
    return proc;
}
```
把proc进行初步初始化（即把proc_struct中的各个成员变量清零），这里可以根据后面proc_init时对alloc_proc函数的检查获取各参数变量应被初始化为何值。

struct context context和struct trapframe *tf成员变量表面上都保存的是进程的上下文，但是trapframe保存的是用户态内核态的上下文，而context保存的是线程当前的上下文，可能是执行用户代码的上下文，也可能是执行内核代码的上下文。

进程之间通过进程调度来切换控制权，当某个fork出的新进程获取到了控制流后，此时新进程仍处于内核态，但实际上我们想在用户态中执行代码，所以我们需要从内核态切换回用户态，也就是中断返回。要让新进程执行终端返回，就要用proc->context.eip = (uintptr_t)forkret，forkret会使新进程正确的从中断处理例程中返回。而中断返回时，新进程会恢复保存的trapframe信息至各个寄存器中，然后开始执行用户代码。

### 练习2：为新创建的内核线程分配资源（需要编码）

创建一个内核线程需要分配和设置好很多资源。kernel_thread函数通过调用do_fork函数完成具体内核线程的创建工作。do_kernel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们实际需要"fork"的东西就是stack和trapframe。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：

    调用alloc_proc，首先获得一块用户信息块。
    为进程分配一个内核栈。
    复制原进程的内存管理信息到新进程（但内核线程不必做此事）
    复制原进程上下文到新进程
    将新进程添加到进程列表
    唤醒新进程
    返回新进程号

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

    请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

do_fork函数：
```C++
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    if ((proc = alloc_proc()) == NULL) {
        goto fork_out;
    }
    proc->parent = current;
    if (setup_kstack(proc) != 0) {
        goto bad_fork_cleanup_kstack;
    }
    if (copy_mm(clone_flags, proc) != 0) {
        goto bad_fork_cleanup_proc;
    }
    copy_thread(proc, stack, tf);
    proc->pid = get_pid();
    hash_proc(proc);
    list_add(&proc_list, &proc->list_link);
    nr_process++;
    wakeup_proc(proc);
    ret = proc->pid;
fork_out:
    return ret;
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
```
如果前3步执行没有成功，则需要做对应的出错处理，把相关已经占有的内存释放掉。这里主要有三个部分：

1. 如果分配进程失败，即``alloc_proc()``失败，那么由于没有分配资源，直接退出即可，也就是这里的``goto fork_out``。
2. 如果这里分配进程成功了，但在栈的分配时失败了，那么就需要操作系统来对栈进行回收，所以这里需要先回收栈，再去回收进程。
3. 如果以上都成功了，但在复制当前进程的内存管理空间信息时失败，那么这里就是清除进程，然后直接返回。

同时proc的parent指针记录的是进程的父进程，在本次实验中，也就是设置idleproc内核线程为initproc内核线程的父进程，而idleproc内核线程没有父进程。

给每个新fork的线程一个唯一的id涉及到的是get_pid()函数。
```C++
static int
get_pid(void) {
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    if (++ last_pid >= MAX_PID) {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe) {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list) {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid) {
                if (++ last_pid >= next_safe) {
                    if (last_pid >= MAX_PID) {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid) {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}
```
首先在get_pid函数中使用``next_safe``和``last_pid``两个变量记录此函数对pid的分配情况，此两变量为静态变量，函数退出之后并不销毁，因此用来维护pid的分配状态，表示从``last_pid``到``next_safe``之间并没有其他已占用的线程号。

因此当``++last_pid < next_safe``，可以直接返回自增后的``last_pid``（对应控制流为第一个if处last_pid自增，不进入条件体；第二个if处检查last_pid并没有超出范围，不进入条件体，直接返回last_pid），此为情况1。

当``++last_pid>=MAX_PID``（第一个if的条件），表示MAX_PID内的进程号已经循环过一轮，需要重新计数，因此将last_pid置为1，并``goto inside``，将``next_safe``暂且置为MAX_PID，并执行标签repeat对应的代码。repeat对应代码的作用为以当前last_pid为起点，找出下一段合法的[last_pid,next_safe]区间，此为情况2。

关于repeat标号下的代码，其具体功能实现如下：

repeat的核心功能其实实现于while中下面的else if，即从当前进程表中找出pid大于last_pid的pid最小的进程，将其pid作为next_safe，那么在接下来last_pid继续自增的过程中，在到达next_safe之前，并不会与任何已经存在的pid冲突，即我们得到了上面说的下一段合法的[last_pid,next_safe]区间。但是，这样的实现只保证了区间的右端安全，左端的last_pid是由last_pid自增越过上一个next_safe或最大边界得来的，其仍有可能与某个进程的pid冲突，因此我们有while中的第一个if，即``if (proc->pid == last_pid)``来保证这种情况出现时，我们尝试继续右移last_pid，并重新开始repeat的过程，直到区间左端也合法。

当``++last_pid >= next_safe`` 并且自增后last_pid并不超过MAX_PID时，为情况三，控制流为不进入第一个if而进入第二个if，通过上面解释的repeat段代码来实现找出下一段合法的[last_pid,next_safe]区间，并返回last_pid；

综上，ucore通过get_pid()函数，可以给每一个线程一个唯一的pid。当然当当前运行的进程数目等于MAX_PID时，get_pid()会陷入无限的循环，必须有进程释放后才能获取到pid。


### 练习3：编写proc_run 函数（需要编码）

proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

    检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
    禁用中断。你可以使用/kern/sync/sync.h中定义好的宏local_intr_save(x)和local_intr_restore(x)来实现关、开中断。
    切换当前进程为要运行的进程。
    切换页表，以便使用新进程的地址空间。/libs/riscv.h中提供了lcr3(unsigned int cr3)函数，可实现修改CR3寄存器值的功能。
    实现上下文切换。/kern/process中已经预先编写好了switch.S，其中定义了switch_to()函数。可实现两个进程的context切换。
    允许中断。

请回答如下问题：

    在本实验的执行过程中，创建且运行了几个内核线程？

proc_run函数：
```C
void
proc_run(struct proc_struct *proc) {
    if (proc != current) {
        int intr_flag;
        struct proc_struct *prev = current, *next = proc;
        local_intr_save(intr_flag);
        {
            current = proc;
            lcr3(next->cr3);
            switch_to(&(prev->context), &(next->context));
        }
        local_intr_restore(intr_flag);
    }
}
```
这里编程需要注意的是，要最开始就把当前进程的指针指向新进程，所以需要开始时保存原本的当前线程，如果先进行switch，然后再把当前进程的指修改，就会出现缺页异常。此外这里还更新了``cr3``，cr3本质上是x86中的一个寄存器，是用来记录页表的寄存器，其实这里其实就是satp寄存器，这里进行页表的替换，就是处理不同的进程之间不同的虚拟地址映射关系。

本次实验创建且运行了2个内核线程，分别为``idleproc``内核线程和``initproc``内核线程，其中``idleproc``内核线程是``initproc``内核线程的父线程，``idleproc``内核线程的工作就是不停地查询，看是否有其他内核线程可以执行了，所以``idleproc``内核线程是在ucore操作系统没有其他内核线程可执行的情况下才会被调用。接着就是调用``kernel_thread``函数来创建``initproc``内核线程。在``kernel_thread``函数中，代码为：
```C
// kernel_thread - create a kernel thread using "fn" function
// NOTE: the contents of temp trapframe tf will be copied to 
//       proc->tf in do_fork-->copy_thread function
int
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
    struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe));
    tf.gpr.s0 = (uintptr_t)fn;
    tf.gpr.s1 = (uintptr_t)arg;
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
    tf.epc = (uintptr_t)kernel_thread_entry;
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
}
```
这里实际上处理的就是：

1. 设定函数及参数：也就是这里的``tf.gpr.s0``和``tf.gpr.s1``，从而处理线程的函数。
2. 然后设定内核的状态，也就是得到当前的sstatus即得到csr寄存器状态，然后设定中断后进入内核态(SSTATUS_SPIE)，设定处于supverisor状态(SSTATUS_SPIE)，然后禁用中断(~SSTATUS_SIE)，最后设定返回地址，再去调用do_fork()函数(``do_fork(clone_flags | CLONE_VM, 0, &tf)``)，这里表示的其实是共享空间(因为RISCV中内核线程是共享内核空间的)。
3. 于是我们就得到了一个新的内核线程。

### 扩展练习 Challenge：

#### 说明语句local_intr_save(intr_flag);....local_intr_restore(intr_flag);是如何实现开关中断的？
首先简单说明下两个的宏定义处理：
```C
#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)
#define local_intr_restore(x) __intr_restore(x);
```
这里主要利用的是C语言中对于宏定义的一个处理，通过宏定义调用函数，这里使用``do...while(0)``，其实是为了保证内部被编译器认为是一个语法块，如果直接使用，否则可能会出现形如：
    
    local_intr_save(x) x = __intr_save();
    在调用时：
    if (some_condition)
        local_intr_save(saved_state);
    else
        some_other_function();
    那么会被辨认为：    
    if (some_condition)
        x = __intr_save();
    else
        some_other_function();
    导致错误。
然后这里的处理是：
```C
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}
```
也就是说，如果这时中断没有被禁止，即(read_csr(sstatus) & SSTATUS_SIE)为真，那么说明可以终止中断，这里记录x其实是为了保证不会出现中断没有被禁止时，又调用``intr_enable()``函数取消禁用。

再进一步看，这里的``intr_disable()``和``intr_enable()``函数，代码为：
```C
/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
```
这里其实就是调用了RISCV的``riscv.h``中的内联汇编，用于设定csr寄存器。