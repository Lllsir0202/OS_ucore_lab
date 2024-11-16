### 练习

对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点
 
#### 练习0：填写已有实验
本实验依赖实验1/2。请把你做的实验1/2的代码填入本实验中代码中有“LAB1”,“LAB2”的注释相应部分。

#### 练习1：理解基于FIFO的页面替换算法（思考题）
描述FIFO页面置换算法下，一个页面从被换入到被换出的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏），并用简单的一两句话描述每个函数在过程中做了什么？（为了方便同学们完成练习，所以实际上我们的项目代码和实验指导的还是略有不同，例如我们将FIFO页面置换算法头文件的大部分代码放在了`kern/mm/swap_fifo.c`文件中，这点请同学们注意）
 - 至少正确指出10个不同的函数分别做了什么？如果少于10个将酌情给分。我们认为只要函数原型不同，就算两个不同的函数。要求指出对执行过程有实际影响,删去后会导致输出结果不同的函数（例如assert）而不是cprintf这样的函数。如果你选择的函数不能完整地体现”从换入到换出“的过程，比如10个函数都是页面换入的时候调用的，或者解释功能的时候只解释了这10个函数在页面换入时的功能，那么也会扣除一定的分数
  
答：在fifo函数中，我们首先进行初始化后，整个过程都是在缺页中断后的处理函数``do_pgfault``中进行的。

下面详细介绍下主要过程：
  1. do_pgfault函数：在触发缺页异常时被调用，整体实现换入需要的页，并在满时换出按替换策略剔除的页。
  2. find_vma函数：这个函数根据发生中断的地址，尝试找到对应的连续虚拟内存块。
  3. 使用PTE_U宏定义，这里是对新的页进行权限设置，先设设定为用户权限，若有其他权限，则进行一个与运算。
  4. get_pte函数：这个函数用来根据虚拟地址来取得对应的页表项，这里create参数为1,表示创建一个新的页表项。
  5. pgdir_alloc_page函数：这个函数用于在该页表项中分配一个页，同时设定这个页的虚拟地址和可以使用的权限。
  6. 这里调用了宏alloc_page():这个宏就是alloc_pages(1)的调用，所以在这里我们进行了页的分配。
  7. alloc_pages函数：在这个函数中，首先尝试调用pmm_manager进行分配页，如果分配失败，那么就需要将页进行移出，所以这里调用了swap_out函数进行处理。
  8. swap_out函数：这个函数实现的是对页按照设定策略的换出，这里则是fifo的方法，这里同样通过指针指向来处理的，这里在swap_out函数中调用swap_out_victim获得被剔除的页，然后将对应的页表清空，写回内存。
  9. _fifo_swap_out_victim函数：这个函数实现的是处理fifo算法下的剔除情况，这里剔除head前向节点，也就是尾部节点，即除去最早进入的页。
  10. swap_in函数：这个函数则是通过给出的虚拟地址，去查询页表，并且这里设定create参数为0,表示这里不会创建新的页表项，然后从该页表项中读取页，最后由引用的方式返回得到的页。
  11. page_insert函数：这里实现的是将这个页插入对应虚拟地址的页表项中，同时设定权限。
  12. swap_map_swappable函数：这个函数是通过指针指向的，这里实现的就是将page插入fifo的链表头中。

#### 练习2：深入理解不同分页模式的工作原理（思考题）
get_pte()函数（位于`kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。
 - get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。

答：sv39中，在一个三级页表结构，一个39位线性地址la可以分为4个部分，分别9位三级页表索引，9位二级页表索引，9位一级页表索引和12位页内偏移。而三级页表和二级页表映射的不是真正的页，而是页表的页表，因此在查找或者创建的过程非常相似。在查找页表项时，最终需要查找到映射具体页的页表项，这个过程需要先定位三级页表，通过三级页表定位二级页表，最后通过二级页表定位一级页表，再通过页内偏移定位到页表项。因此，如何在这一过程中，某一级页表不存在，就需要先进行创建。

在get_pte()函数中，前两段相似的代码就是分别定位三级页表和二级页表，并且在发现页表不存在时进行创建的过程。而由于这两级页表作为页表的页表，且本质上仍然是页，因此对他们定位以及创建的过程非常相似。

而在sv32，sv48中，虚拟地址的位数与结构不同，对应的是页表的结构不同，sv32采用二级页表，sv48采用四级页表，因此其对应页表项的查找和创建过程也不一致。但是根据sv39中的相关函数，我们可以对其进行推测。如sv48中会有三段相似的代码，多出的一段代码将完成四级页表的查找与创建，而sv32中将会删去三级页表的相关代码。

- 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

答：对页表项的分配存在多种不同的情况，其中可能涉及多个过程，如在三级页表不存在时先创建三级页表，在二级页表不存在时创建二级页表。这些过程首先先要对页表进行定位，从而产生是否存在的信号，而又都统一被特定的相同的控制信号调控，从而产生复杂的运行逻辑。

将页表项的查找和分配合并在一个函数里，对相关的逻辑进行封装，减少了外部逻辑对页表操作的干扰，从而能够保证操作的准确性。

#### 练习3：给未被映射的地址映射上物理页（需要编程）
补充完成do_pgfault（mm/vmm.c）函数，给未被映射的地址映射上物理页。设置访问权限 的时候需要参考页面所在 VMA 的权限，同时需要注意映射物理页时需要操作内存控制 结构所指定的页表，而不是内核的页表。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
 - 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。
 - 如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？
- 数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？

##### 设计实现过程

do_pgfault系发生缺页异常时的处理函数，其功能为给未被映射的地址映射上物理页，函数原型为```int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr)```。在我们编程实现的部分，先使用```swap_in(mm,addr,&page);```将addr对应的物理页交换到内存中，并获取指向这个页的指针page。

接下来使用```page_insert(mm->pgdir,page,addr,perm);```函数将page在页表中建立映射，其中perm是访问权限，其值的设置参考了VMA的权限，当vma可写时，才设置页面的权限PTE_R | PTE_W，即可读可写。

最后使用```swap_map_swappable(mm, addr, page, 1);```将此页面设置成可交换，即维护进入页面交换算法中。并设置```page->pra_vaddr = addr;```为page标记当前映射到的虚拟地址。

##### 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。

PDE和PTE都是页表的组成部分，是建立虚拟内存与物理内存之间映射关系的重要内容。在实现页面替换算法时，我们看到的往往是虚拟地址，必须经过页表的转换，即获取虚拟地址对应的页表项PTE，才能访问到对应物理页，在页面替换算法中，pte起类似page指针的作用，实际使用的是其53-10位上的物理页号。如在页面换入过程中，将数据从磁盘（一块封装的内存）读到空白页时，其调用```int swapfs_read(swap_entry_t entry, struct Page *page)函数```，其传入的entry实际即一个页表项。

而PDE是索引PTE过程中不可缺少的部分，一方面，其作为页表入口存储在mm_srtuct中；另一方面，其通过逐级索引，使得能够通过虚拟地址获取PDE。

##### 如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？

页访问异常时，硬件将设置一些寄存器，如sepc，scause，stval等，即Ucore中的trapframe，为异常处理提供信息。并跳转到stvec，由操作系统处理异常。具体而言，对页访问异常，trapframe->cause可能为CAUSE_LOAD_PAGE_FAULT或CAUSE_STORE_PAGE_FAULT。

page的结构如下
```
struct Page {
    int ref;                        
    uint_t flags;                 
    uint_t visited;
    unsigned int property;         
    list_entry_t page_link;         
    list_entry_t pra_page_link;     
    uintptr_t pra_vaddr;            
};
```
其中的list_entry_t page_link;与list_entry_t pra_page_link;都可看作一个page指针（计算偏移之后），而page指针实际上是一个page的物理地址，可通过page2ppn(page*)获取物理页号，这实际上就是页目录项和页表项中实际存储的核心数据。

此外，其中的par_vaddr存储了此page目前映射的虚拟地址，可使用此地址通过PDE和PTE索引到此page。

#### 练习4：补充完成Clock页替换算法（需要编程）
通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（mm/swap_clock.c）。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
 - 比较Clock页替换算法和FIFO算法的不同。

- 比较Clock页替换算法和FIFO算法的不同。

1、初始化pra_list_head为空链表，初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头，将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作。
```C++
static int
_clock_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
     curr_ptr = &pra_list_head;
     return 0;
}
```
2、将页面page插入到页面链表pra_list_head的末尾，将页面的visited标志置为1，表示该页面已被访问。
```C++
static int
_clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry=&(page->pra_page_link);
    assert(entry != NULL && curr_ptr != NULL);
    list_entry_t *head = &pra_list_head;
    list_add(head, entry);
    page->visited = 1;
    return 0;
}
```

3、编写代码，遍历页面链表pra_list_head，查找最早未被访问的页面，获取当前页面对应的Page结构指针；如果当前页面未被访问，则将该页面从页面链表中删除，并将该页面指针赋值给ptr_page作为换出页面；如果当前页面已被访问，则将visited标志置为0，表示该页面已被重新访问。
```C++
static int
_clock_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    assert(head != NULL);
    assert(in_tick==0);
    curr_ptr = list_prev(head);
    if(curr_ptr == head){ //排除链表本身为空的情况
        *ptr_page = NULL;
        return 0;
    } 
    while (1) {
        struct Page* curr_page = le2page(curr_ptr, pra_page_link);
        if(curr_ptr == head){ //当每个页面都被访问过，就会出现绕了一整圈的情况
            curr_ptr = list_prev(curr_ptr);
            continue;
        }
        if(curr_page->visited == 0){    
            list_del(curr_ptr);
            *ptr_page = curr_page;
            cprintf("curr_ptr %p\n",curr_ptr); //输出curr_ptr
            break;
        }
        else {
            curr_page->visited = 0;
            cprintf("curr_ptr %p\n",curr_ptr);
            curr_ptr = list_prev(curr_ptr);
        }
    }
    return 0;
}
```
- 先进先出(First In First Out, FIFO)页替换算法：该算法总是淘汰最先进入内存的页，即选择在内存中驻留时间最久的页予以淘汰。只需把一个应用程序在执行过程中已调入内存的页按先后次序链接成一个队列，队列头指向内存中驻留时间最久的页，队列尾指向最近被调入内存的页。这样需要淘汰页时，从队列头很容易查找到需要淘汰的页。FIFO 算法只是在应用程序按线性顺序访问地址空间时效果才好，否则效率不高。因为那些常被访问的页，往往在内存中也停留得最久，结果它们因变“老”而不得不被置换出去。FIFO 算法的另一个缺点是，它有一种异常现象（Belady 现象），即在增加放置页的物理页帧的情况下，反而使页访问异常次数增多。

- 时钟（Clock）页替换算法：是 LRU 算法的一种近似实现。时钟页替换算法把各个页面组织成环形链表的形式，类似于一个钟的表面。然后把一个指针（简称当前指针）指向最老的那个页面，即最先进来的那个页面。另外，时钟算法需要在页表项（PTE）中设置了一位访问位来表示此页表项对应的页当前是否被访问过。当该页被访问时，CPU 中的 MMU 硬件将把访问位置“1”。当操作系统需要淘汰页时，对当前指针指向的页所对应的页表项进行查询，如果访问位为“0”，则淘汰该页，如果该页被写过，则还要把它换出到硬盘上；如果访问位为“1”，则将该页表项的此位置“0”，继续访问下一个页。该算法近似地体现了 LRU 的思想，且易于实现，开销少，需要硬件支持来设置访问位。时钟页替换算法在本质上与 FIFO 算法是类似的，不同之处是在时钟页替换算法中跳过了访问位为 1 的页。

#### 练习5：阅读代码和实现手册，理解页表映射方式相关知识（思考题）
如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？

如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？

##### 优势

1. 速度提升。由于使用一个大页，可以由页内偏移直接索引到页表项，相对多级页表的多次索引而言，减少了访存次数，提升了访问速度。

2. 简化编程。在由虚拟地址获取页表项的过程中，我们不需要像练习2的get_pte()那样重复多次获取页表地址->索引下一级的过程，而只需要由虚拟地址直接索引，这一定程度上简化了程序编写的过程。

##### 坏处

1. 空间浪费。当使用一个大页时，无论要映射的内存有多大，页表占用的空间都是固定的一个大页。当需要映射的空间很小或很零散时，多级页表只需要创建对应的几个小页进行索引，而这种方式将不得不继续占用一个大页的空间，这是显著的空间浪费。

#### 扩展练习 Challenge：实现不考虑实现开销和效率的LRU页替换算法（需要编程）
challenge部分不是必做部分，不过在正确最后会酌情加分。需写出有详细的设计、分析和测试的实验报告。完成出色的可获得适当加分。

答：在这里首先简单介绍下lru策略，这个算法，其实就是说当有一个页在很长一段时间内，没有被访问时，我们有充分的理由认为短期内它不会被使用，所以当我们出现缺页且页表已经满了的情况下，我们会优先将这些在很长时间内没有使用的页换出。在这里我的思路主要如下：

对于init部分，和fifo完全相同，没有什么需要做的，这里就是将初始的链表进行一些赋值的初始化。

    static int
    _lru_init_mm(struct mm_struct *mm)
    {     
        list_init(&pra_list_head);
        mm->sm_priv = &pra_list_head;
        //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
        return 0;
    }

在lru算法中，在``_lru_map_swappable``中，这里每次发生缺页时，我们将新的页插入到最前面即可，主要的计算应该发生在访问阶段，也就是说当访问一次页表，如果在页表内，我们需要将该页移动到开头，然后在寻找victim时，直接将head的前节点，也就是链表尾的节点返回即可。

    static int
    _lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
    {
        list_entry_t *head=(list_entry_t*) mm->sm_priv;
        list_entry_t *entry=&(page->pra_page_link);
    
        assert(entry != NULL && head != NULL);

        // 将当前entry串到头节点后即可。
        list_add(head, entry);
        return 0;
    }

在此外，我们还需要设计一个访问函数，在每次访问地址前，我们需要将这个地址标记访问一次，从而保证lru每次访问时，会将访问的页移动到链表的最前面即head后的节点位置。

我们实现一个访问函数命名为 ``_lru_access``，用于在访问地址后使用，这时如果访问了地址，那么我们就需要对lru的list进行一个重新排序，将最近访问的放在最前面，然后在剔除时剔除链表尾的数据。

    static int
    _lru_access(uintptr_t addr)
    {
        list_entry_t *head= &pra_list_head;
        
    
        // assert(entry != NULL && head != NULL);

        // 对这个地址在当前的链表中进行一个遍历，如果存在，则将其加到最前
        list_entry_t *p = list_next(head);
        struct Page *page;
        while(1)
        {
            page = le2page(p, pra_page_link);
            // 说明有相同的->但这里一定会有相同的
            if(page->pra_vaddr == addr)
            {
                break;
            }
            if(p != head)
            {
                p = list_next(p);
            }
            else {
                break;
            }
        }
        list_entry_t *entry = &(page->pra_page_link);
        list_del(p);
        list_add(head, entry);
        cprintf("page addr 0x%x\n", entry);
        return 0;
    }

这里值得注意的是对于FIFO和clock算法，所有的过程都只需要在出现缺页异常时处理，但LRU算法需要在每次访存时都进行计算，从而将访问进行一个记录，使得最先被访问的页位于链表尾，在选择victim时，选择并剔除。

这里采用的测试如下：

    static int
    _lru_check_swap(void) {
        cprintf("write Virt Page c in lru_check_swap\n");
        *(unsigned char *)0x3000 = 0x0c;
        _lru_access((unsigned char *)0x3000)  ;
        assert(pgfault_num==4);
        cprintf("write Virt Page a in lru_check_swap\n");
        *(unsigned char *)0x1000= 0x0a;
        _lru_access((unsigned char *)0x1000) ;
        assert(pgfault_num==4);
        cprintf("write Virt Page d in lru_check_swap\n");
        *(unsigned char *)0x4000 = 0x0d;
        _lru_access((unsigned char *)0x4000) ;
        assert(pgfault_num==4);
        cprintf("write Virt Page b in lru_check_swap\n");
        *(unsigned char *)0x2000 = 0x0b;
        _lru_access((unsigned char *)0x2000) ;
        assert(pgfault_num==4);

        // 2 -> 4 -> 1 -> 3

        cprintf("write Virt Page e in lru_check_swap\n");
        *(unsigned char *)0x5000 = 0x0e;
        _lru_access((unsigned char *)0x5000);
        assert(pgfault_num==5);

        // 5 -> 2 -> 4 -> 1

        cprintf("write Virt Page b in lru_check_swap\n");
        *(unsigned char *)0x2000 = 0x0b;
        _lru_access((unsigned char *)0x2000);
        assert(pgfault_num==5);

        // 2 -> 5 -> 4 -> 1

        cprintf("write Virt Page a in lru_check_swap\n");
        *(unsigned char *)0x1000 = 0x0a;
        _lru_access((unsigned char *)0x1000);

        // 1 -> 2 -> 5 -> 4

        assert(pgfault_num==5);
        //assert(pgfault_num==6);
        cprintf("write Virt Page b in lru_check_swap\n");
        *(unsigned char *)0x2000 = 0x0b;
        _lru_access((unsigned char *)0x2000);

        // 2 -> 1 -> 5 -> 4
        assert(pgfault_num==5);

        cprintf("write Virt Page c in lru_check_swap\n");
        
        *(unsigned char *)0x3000 = 0x0c;
        _lru_access((unsigned char *)0x3000);

        // 3 -> 2 -> 1 -> 5

        assert(pgfault_num==6);
        cprintf("write Virt Page d in lru_check_swap\n");
        
        *(unsigned char *)0x4000 = 0x0d;
        _lru_access((unsigned char *)0x4000);

        // 4 -> 3 -> 2 -> 1

        assert(pgfault_num==7);
        cprintf("write Virt Page e in lru_check_swap\n");
        
        *(unsigned char *)0x5000 = 0x0e;
        _lru_access((unsigned char *)0x5000);

        // 5 -> 4 -> 3 -> 2

        assert(pgfault_num==8);
        cprintf("write Virt Page a in lru_check_swap\n");
        assert(*(unsigned char *)0x2000 == 0x0b);

        // 2 -> 5 -> 4 -> 3
        
        *(unsigned char *)0x1000 = 0x0a;
        _lru_access((unsigned char *)0x1000);

        // 1 -> 2 -> 5 -> 4

        assert(pgfault_num==9);
        return 0;
    }

在测试中测试了对于lru_list中的数据进行了check，同时依据page_fault情况进行check，检测没有问题。

这里如果正常使用，可以封装访存为返回值为addr的函数，从而通过*(unsigned char*)_lru_access(addr)这种形式进行访存，或者采取另一种封装形式:lru_access(addr, val)的形式来处理，然后采用宏的方式，将addr = val进行这种形式的映射即可。