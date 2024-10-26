## lab0

## 从上电到操作系统启动的流程

由于CPU本身无法直接执行操作系统，即不可能使用操作系统来启动操作系统，故需要其他的硬件来进行配套使用，在这里实际上使用的是bootloader的程序，
是一种软件和硬件协同的方式将操作系统运行起来的，主要流程如下：
</br>

1.  上电，即按下电源键或复位，这里不同的cpu设计使用的复位向量地址不同，在qemu-4.1.1中采用的是0x1000，即加电后，不会第一时间启动操作系统，而是需要一些准备工作，这个过程在x86架构中主要是通过BIOS或UEFI完成的，在qemu中则是由OpenSBI完成的，在0x1000地址开始，OpenSBI进行了对于系统信息的一系列重置操作，即将计算机系统的各个部件重置为初始状态，并启动bootloader

2.  bootloader启动操作系统，在这个实验中，bootloader的地址在0x80000000，bootloader启动，os.bin加载到地址0x80200000位置处，bootloader启动操作系统，将控制权转移给操作系统，在这里就是进入了kern/init/entry.S，进行初始栈分配，注意到这里的栈分配是按照页来分配的，在本实验中是2x4096B的空间大小，然后进入init.c进行操作系统的初始化操作

## 过程分析(gdb)

首先进入0x1000可以看到这里进行一些初始代码：
>  0x1000:	auipc	t0,0x0
   0x1004:	addi	a1,t0,32
   0x1008:	csrr	a0,mhartid
   0x100c:	ld	t0,24(t0)
   0x1010:	jr	t0
   0x1014:	unimp
   0x1016:	unimp
   0x1018:	unimp
   0x101a:	0x8000
这里记录使用a0记录下csr中的mhardtid，即cpu核心标识

此后，跳转到0x80000000处，由于t0+24数据段位置存储的是0x80000000，跳转后，可以看到进入了bootloader阶段，即通过OpenSBI进行操作系统启动，再看0x80200000处，可以看到跳转到操作系统的启动阶段，这时'make debug'终端出现了OpenSBI的标识，再回到0x80200000处，可以看到进入了'kern_entry.S'进行栈分配，这里设定的栈大小是2pages，但分配的是3pages，（？）

然后就会调用'kern_init.c'进行内核初始化，从而输出一个string并进入死循环。

## 练习1: 使用GDB验证启动流程

### 最小可执行内核启动

进入代码框架lab0，依次
`make debug`并在另一个终端`make gdb`
以启动
qemu模拟的RISC-V计算机上的最小可执行内核，并用gdb接入以进行调试。

### 启动流程

使用gdb接入后，查看当前指令，指令内容如下所示。
```
   0x1000:      auipc   t0,0x0
   0x1004:      addi    a1,t0,32
   0x1008:      csrr    a0,mhartid
   0x100c:      ld      t0,24(t0)
   0x1010:      jr      t0
   0x1014:      unimp
   0x1016:      unimp
   0x1018:      unimp
   0x101a:      0x8000
   0x101c:      unimp
```
我们发现初次进入时，进入的位置为0x1000，并且在0x1010处存在跳转指令。我们在此条跳转指令处打上断点，以查看跳转到的位置。使用如下指令

```
break *0x1010
c
info r t0
```
依次输出如下：
```
break *0x1010
Continuing.
t0             0x80000000       2147483648
```
即，当执行到0x1010后，下一步将跳转到0x80000000。使用命令`si`执行下一条指令，发现当前已跳转到0x80000000。

查看0x80000000开始处指令，内容如下。
```
0x80000000:  csrr    a6,mhartid
   0x80000004:  bgtz    a6,0x80000108
   0x80000008:  auipc   t0,0x0
   0x8000000c:  addi    t0,t0,1032
   0x80000010:  auipc   t1,0x0
   0x80000014:  addi    t1,t1,-16
   0x80000018:  sd      t1,0(t0)
   0x8000001c:  auipc   t0,0x0
   0x80000020:  addi    t0,t0,1020
   0x80000024:  ld      t0,0(t0)
   0x80000028:  auipc   t1,0x0
   0x8000002c:  addi    t1,t1,1016
   0x80000030:  ld      t1,0(t1)
   0x80000034:  auipc   t2,0x0
   0x80000038:  addi    t2,t2,988
   0x8000003c:  ld      t2,0(t2)
   0x80000040:  sub     t3,t1,t0
   0x80000044:  add     t3,t3,t2
   0x80000046:  beq     t0,t2,0x8000014e
```
根据指导书，我们知道被加载到这个位置的是作为 bootloader 的 OpenSBI.bin ，bootloader即一个负责开机和加载操作系统的程序。

执行到0x80000046后跳转到0x8000014e，观察这期间的代码，我们发现其中，首先使用csrr指令获取当前硬件线程标识，接着如果不是主核心（标识不为0）则跳转，此处我们启动的是主核心，故没有跳转，接下来执行了一系列加载和判断，最后跳转。

跳转后执行了较长的一段指令，根据bootloader的功能，我们推测此为进行一系列包括内存和寄存器的初始化操作。于是我们在理论上的入口点0x80200000设置断点，并使程序继续执行直到击中断点。
```
(gdb) break *0x80200000
Breakpoint 1 at 0x80200000: file kern/init/entry.S, line 7.
(gdb) continue
Continuing.

Breakpoint 1, kern_entry () at kern/init/entry.S:7
7           la sp, bootstacktop
```
我们发现设置的断点位置为file kern/init/entry.S, line 7.，查看此入口点，我们发现此汇编代码的功能为分配内存栈，然后跳转到kern_init。对kern_init设置断点，我们发现实际上此真正的入口点实际就在0x8020000a处。
```
(gdb) x/10i $pc
=> 0x80200000 <kern_entry>:     auipc   sp,0x3
   0x80200004 <kern_entry+4>:   mv      sp,sp
   0x80200008 <kern_entry+8>:   j       0x8020000a <kern_init>
   0x8020000a <kern_init>:      auipc   a0,0x3
   0x8020000e <kern_init+4>:    addi    a0,a0,-2
   0x80200012 <kern_init+8>:    auipc   a2,0x3
   0x80200016 <kern_init+12>:   addi    a2,a2,-10
   0x8020001a <kern_init+16>:   addi    sp,sp,-16
   0x8020001c <kern_init+18>:   li      a1,0
   0x8020001e <kern_init+20>:   sub     a2,a2,a0
 ```
 我们发现，此处的指令，长度为2字节或4字节不等。分析kern_init函数的内容，其内容如下：
 ```
 int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
   while (1)
        ;
}
 ```
 其功能包括初始化一块内存空间，打印提示信息，接着进入死循环，说明操作系统已成功开机。
 
 ## 问题回答
 ### RISC-V硬件加电后的几条指令在哪里？
 在0x1000，执行到0x1010，是指定的复位地址。
 
 ### 完成了哪些功能？
 其作用为跳转到bootloader，在本实验中，其起始位置为0x80000000。
 1. `0x1000:      auipc   t0,0x0`  加载pc+0到t0，t0此时为0x1000。
 1. ` 0x1004:      addi    a1,t0,32` 将a1置为0x1020。
 1. `0x1008:      csrr    a0,mhartid` 读取状态寄存器mhartid，存储到a0中。（此寄存器在后面的boot loader中也有加载，用于控制某些分支）
 1. ` 0x100c:      ld      t0,24(t0)` 从24(t0)读取一个双字（bootloader入口地址）。
 ```
 (gdb) x/10xw 0x1018
0x1018: 0x80000000      0x00000000      0xedfe0dd0      0x260d0000
0x1028: 0x38000000      0xb00b0000      0x28000000      0x11000000
0x1038: 0x02000000      0x00000000
```
 1. `0x1010:      jr      t0` 跳转到上面读取到的地址（0x80000000），即进入bootloader。

 ### OS中的知识

从上电到操作系统运行间的过程OS理论中并未提及，理论课上缺少此部分的讲解，直接从进程开始，进入进程转换和调度的部分，此部分内容有所空缺。