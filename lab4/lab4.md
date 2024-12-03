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
如果前3步执行没有成功，则需要做对应的出错处理，把相关已经占有的内存释放掉。这里所有要进行的操作都已经有函数进行了封装，因此只需要调用相应的函数就可以了。同时proc的parent指针记录的是进程的父进程，在本次实验中，也就是设置idleproc内核线程为initproc内核线程的父进程，而idleproc内核线程没有父进程。

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
            if (proc->pid == last_pid)
                last->pid++;
            else if (proc->pid > last_pid && next_safe > proc->pid) {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}
```
这段代码存在很多重复的冗长的代码，所以我在贴代码的时候进行了简化。这段代码最核心的逻辑就是得到的last_pid，也就是我们所要使用的pid，必须小于next_safe的值，否则就是不安全的。而这个next_safe的值会在遍历进程链表时不断得到更新，在没有遍历完之前，即使last_pid小于next_safe，也未必安全。

从这段代码的逻辑来看，如果初始的last_pid和进程链表中的每个进程的pid都不相同，最后就会返回这个初始的last_pid，此时该pid唯一。而如果初始的last_pid和进程链表中的某一个进程的pid相等，例如初始last_pid为3，而链表中进程的pid为1、3、4、5、9，那么最后返回的last_pid会是6，其规律是从last_pid初始值开始链表中第一次出现的不连续的那个值，链表中3、4、5连续，然后没有接下来连续的6，因此最后last_pid就为6。

事实上，初始时last_pid总为1（但是从整个代码逻辑看其实为任何值都没问题），所以从链表中只存在pid = 0的idleproc内核线程开始，每次返回的pid都会是上一次返回的pid值加1。但是该函数拥有很强的鲁棒性，也就是面对各种不同的初值，以及链表中进程pid乱序排列的情况时，都能保证返回唯一的pid值。具体看其实现，其实就是遍历所有链表中的进程控制块，从而寻找到一个安全区域，这个安全区域里面任意一个值都可以作为唯一的pid值，这个安全区域的起始值就是从last_pid初始值开始链表中第一次出现的不连续的那个值，终止值就是最后next_safe的值。上面的例子中，初始last_pid为3，而链表中进程的pid为1、3、4、5、9，通过这个函数，就会形成安全区域6，7，8，next_safe就是9，最后返回的pid就是安全区域的起始值6。

#### 练习3：编写proc_run 函数（需要编码）

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
```C++
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
这里编程需要注意的是，要最开始就把当前进程的指针指向新进程，所以需要开始时保存原本的当前线程，如果先进行switch，然后再把当前进程的指修改，就会出现缺页异常。

本次实验创建且运行了2个内核线程，分别为idleproc内核线程和initproc内核线程，其中idleproc内核线程是initproc内核线程的父线程，idleproc内核线程的工作就是不停地查询，看是否有其他内核线程可以执行了，所以idleproc内核线程是在ucore操作系统没有其他内核线程可执行的情况下才会被调用。接着就是调用kernel_thread函数来创建initproc内核线程。