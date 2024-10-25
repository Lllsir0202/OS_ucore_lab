## lab1

## 重要的注意点

其实这里的trap时钟实际上需要中断使能位置位，才能够触发时钟中断，在这里实际上就是在'sbi_set_timer()'函数调用后，会将sTIP复位，在这段时间内不会再次触发ecall，所以不会导致时钟设置一直被更改的情况。

### 练习1 理解内核启动中的程序入口操作
内核启动时，指令la sp bootstacktop，分配栈空间，使得内核分配使用的栈空间，

## 练习1：理解内核启动中的程序入口操作

### 说明指令 la sp, bootstacktop 完成了什么操作，目的是什么？

la指令，即load address，将一个地址加载到前面的寄存器中,而sp为栈指针，即，此指令将栈指针移动到指定位置。此处，加载的地址为bootstacktop。使用lab0.5中方法进行调试，运行此条指令后，使用`info register`查看得sp的值为`sp             0x80203000       0x80203000 <SBI_CONSOLE_PUTCHAR>`。

其**目的**是初始化堆栈指针，使得我们运行的内核有一个独立的栈空间。这个栈空间可以供内核储存变量等操作。

### tail kern_init 完成了什么操作，目的是什么？

tail指令，即尾调用，作用为跳转到指定地址，但不进行链接。此处其作用为跳转到kern_init这一内核真正的入口点。调用的kern_init中，进行了memset，以及cons_init、idt_init等初始化函数，因此其目的是对内核进行初始化。

## 练习2：完善中断处理

### 代码内容

根据题目要求，首先调用clock_set_next_event();设置下一次时钟中断。这是kern/driver/clock.c中封装的一个函数，功能是100000个时钟周期后产生下一次中断。然后，为了完成每100次时钟中断进行输出，以及十次时钟输出后关机的要求，我们维护了两个计数器并进行对应的条件判断。

这个填空位于interrupt_handler中，当产生中断并且为IRQ_S_TIMER时，会自动调用。填空的部分代码如下所示。

```
case IRQ_S_TIMER:
            clock_set_next_event();
            ticks++;
            if(ticks==TICK_NUM){
                print_ticks();
                num++;
                ticks=0;
                if(num==10){
                    sbi_shutdown();
                }
            }
            break;
```

### 测试结果

输出如下：

```
Special kernel symbols:
  entry  0x000000008020000a (virtual)
  etext  0x00000000802009fc (virtual)
  edata  0x0000000080204010 (virtual)
  end    0x0000000080204028 (virtual)
Kernel executable memory footprint: 17KB
++ setup timer interrupts
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
relx@relx-virtual-machine:~/os_labs/OS_ucore_lab/lab1$
```

每100次中断输出一次100 ticks，输出10次之后关机，切出qemu回到终端，程序运行结果符合预期。

## Challenge1：描述与理解中断流程

### ucore中处理中断异常的流程，mov a0，sp的目的是什么

1. 中断产生

2. 从stvec获取中断入口地址，跳到\_\_alltraps，执行SAVE_ALL以保存x0-x31的所有寄存器。之后`mov a0，sp`并`jal trap`，此处，a0寄存器用于传参，将sp作为参数传递给trap，以使得trap函数能够访问到保存的这些寄存器。

3. trap函数调用trap_dispatch函数，trap_dispatch函数中根据中断类型（tf->cause，此处tf即我们传入的指针sp）来选择性地调用异常处理函数exception_handler或中断处理函数interrupt_handler。

4. 中断处理函数中，继续根据tf->cause的不同类型，选择调用对应的处理语句。比如上文中我们所写的时钟中断处理语句块即interrupt_handler中的case IRQ_S_TIMER:语句块。

5. 函数调用结束，依次返回，直到trapentry.S中，顺序执行接下来的：
    RESTORE_ALL，以恢复上下文；
    sret，使用特权指令返回到U态。


### SAVE_ALL中寄寄存器保存在栈中的位置是什么确定的
首先，各个寄存器的相对位置固定，如x0存放地址为0*REGBYTES(sp)；x1存放于1*REGBYTES(sp)等，具体的位置由产生中断时的栈指针（sp）位置决定。因此，只需记录sp，利用寄存器存放位置与sp相对偏移的规则，就能确定所有寄存器在栈中的保存位置。

### 对于任何中断，\_\_alltraps 中都需要保存所有寄存器吗

并不需要，因为有些中断的处理很简单，并不使用被调用者保存的寄存器，在返回到原位置时，使用的寄存器已经通过类似函数调用后返回的方式被恢复，比如时钟中断，其处理只需要很简单的代码。

但保存全部寄存器也有其优势，比如无需进行复杂的条件判断；并且，就操作系统的性质而言，中断期间可能执行其他的操作，这些操作可能产生新的中断，此时如果选择性地保存寄存器，会产生混乱。

## Challenge2：理解上下文切换机制
>在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？

csrw指令将sp写入sscratch，sscratch是 RISC-V 中用于存放与特权级别相关的临时数据的寄存器，此处用来暂存sp。

csrrw s0, sscratch, x0将sscratch存入s0并将sscratch置为0。此处，前面赋值部分将暂存的sp存入s0以在后边把它store在对应的栈空间中；后边置0部分，是为了设置标记，便于发生递归异常时，表明当前上下文是在内核中执行的，有助于系统在处理异常时进行正确的上下文区分。

不还原它们，是因为这些寄存器用于异常处理，而restore的时刻异常已经处理完毕，这些寄存器中的值已经没有作用，基于效率考虑，不必对齐进行恢复。而之所以存储它们，是因为在异常处理过程中，这些寄存器的值可能变化（如上面提到的递归异常，会导致异常信息变化），要保证异常处理过程中能访问到正确的值。

## Challenge3：完善异常中断
### 代码完成
根据题目要求，此处添加非法指令和断点两种异常的处理函数，处理的要求是输出异常类型与异常指令地址，并更新 tf->epc寄存器，即将pc置于下一条指令处。具体实现部分的代码块如下所示。
```
case CAUSE_ILLEGAL_INSTRUCTION:
     cprintf("Illegal instruction\n");
     cprintf("address 0x%016llx",tf->epc);
     tf->epc+=2;//因为有2字节的指令跟四字节的指令，所以加2，反正错了会中断又加2
     break;
case CAUSE_BREAKPOINT:
     cprintf("breakpoint\n");
     cprintf("address 0x%016llx",tf->epc);
     tf->epc+=2;
     break;
```
我们使用代码框架提供的cprintf接口进行字符串输出，输出内容包括错误类型与指令地址。接下来把epc置于下一条指令，此处，由于在lab0.5中观察到既有二字节指令也有四字节指令，经过思考，此处pc+=2，因为如果应+4，则+2后读到的是非法指令，会再次触发异常，从而回到正确的位置。


### 测试
我们在init处，所有初始化完成系统成功开机而进入死循环前，添加这样两条测试代码
```
asm volatile("ebreak");
asm volatile(".word 0x00000000");
```
分别触发异常与非法指令，相关的运行结果如下。
```
++ setup timer interrupts
breakpoint
address 0x000000008020004e 
Illegal instruction
address 0x0000000080200050 
Illegal instruction
address 0x0000000080200052 
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
```
我们发现成功输出了异常类型与指令地址。
此处，指令为4字节，我们发现程序按照预期，通过两次处理非法指令处理了此次异常。

接下来运行前面实现的时钟中断并关机。输出结果符合预期。

最后，展示`make grade`的输出
```gmake[1]: Leaving directory '/home/relx/os_labs/OS_ucore_lab/lab1'
try to run qemu
qemu pid=116102
  -100 ticks:                                OK
Total Score: 100/100

```
证明实现没有问题。

### OS中的知识

在实验中设计到的三态问题，在OS理论课程中并没有提及，对于三态之间功能的划分和权限理解完全是在实验中查询和实验书上得到的。
