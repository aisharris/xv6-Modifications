#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table.
void procinit(void)
{
  struct proc *p;

  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    initlock(&p->lock, "proc");
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int allocpid()
{
  int pid;

  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc *
allocproc(void)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == UNUSED)
    {
      goto found;
    }
    else
    {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;

  // Allocate a trapframe page.
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if (p->pagetable == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;
  p->rtime = 0;
  p->etime = 0;
  p->ctime = ticks;

  //alarm additions intitialization:
  p->alarm_flag = 0;
  if ((p->alarmtrpfrm = (struct trapframe *)kalloc()) == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }
  p->currticks = 0;
  p->ticks = 0;

  //mlfq additions:
  p->waittime = 0;
  p->inserttime = 0;
  p->priority = 0;

  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if (p->trapframe)
    kfree((void *)p->trapframe);
  p->trapframe = 0;

  //alarm additions
  if (p->alarmtrpfrm)
    kfree(p->alarmtrpfrm);
  p->alarmtrpfrm = 0;

  if (p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
}

// Create a user page table for a given process, with no user memory,
// but with trampoline and trapframe pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if (pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
               (uint64)trampoline, PTE_R | PTE_X) < 0)
  {
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe page just below the trampoline page, for
  // trampoline.S.
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
               (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
  {
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// assembled from ../user/initcode.S
// od -t xC ../user/initcode
uchar initcode[] = {
    0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
    0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
    0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
    0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
    0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
    0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00};

// Set up first user process.
void userinit(void)
{
  struct proc *p;

  p = allocproc();
  initproc = p;

  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;     // user program counter
  p->trapframe->sp = PGSIZE; // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;

  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int growproc(int n)
{
  uint64 sz;
  struct proc *p = myproc();

  sz = p->sz;
  if (n > 0)
  {
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    {
      return -1;
    }
  }
  else if (n < 0)
  {
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if ((np = allocproc()) == 0)
  {
    return -1;
  }

  // Copy user memory from parent to child.
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
  {
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for (i = 0; i < NOFILE; i++)
    if (p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void reparent(struct proc *p)
{
  struct proc *pp;

  for (pp = proc; pp < &proc[NPROC]; pp++)
  {
    if (pp->parent == p)
    {
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void exit(int status)
{
  struct proc *p = myproc();

  if (p == initproc)
    panic("init exiting");

  // Close all open files.
  for (int fd = 0; fd < NOFILE; fd++)
  {
    if (p->ofile[fd])
    {
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);

  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;
  p->etime = ticks;

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int wait(uint64 addr)
{
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (pp = proc; pp < &proc[NPROC]; pp++)
    {
      if (pp->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if (pp->state == ZOMBIE)
        {
          // Found one.
          pid = pp->pid;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
                                   sizeof(pp->xstate)) < 0)
          {
            release(&pp->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(pp);
          release(&pp->lock);
          release(&wait_lock);
          return pid;
        }
        release(&pp->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || killed(p))
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void scheduler(void)
{

  //RR start
  struct proc *p;
  struct cpu *c = mycpu();

  c->proc = 0;

  #ifdef MLFQ

  Queue AofQueues[4];

  
  struct Queue que0;
  que0.front = -1;
  que0.rear = -1;
  que0.size = NPROC;
  struct proc* arr0[NPROC];
  que0.arr = arr0;
  for(int i = 0; i < NPROC; i++)
  {
    que0.arr[i] = 0;
  }

  AofQueues[0]= &que0;

  struct Queue que1;
  que1.front = -1;
  que1.rear = -1;
  que1.size = NPROC;
  struct proc* arr1[NPROC];
  que1.arr = arr1;
  for(int i = 0; i < NPROC; i++)
  {
    que1.arr[i] = 0;
  }

  AofQueues[1]= &que1;

  struct Queue que2;
  que2.front = -1;
  que2.rear = -1;
  que2.size = NPROC;
  struct proc* arr2[NPROC];
  que2.arr = arr2;
  for(int i = 0; i < NPROC; i++)
  {
    que2.arr[i] = 0;
  }

  AofQueues[2]= &que2;

  struct Queue que3;
  que3.front = -1;
  que3.rear = -1;
  que3.size = NPROC;
  struct proc* arr3[NPROC];
  que3.arr = arr3;
  for(int i = 0; i < NPROC; i++)
  {
    que3.arr[i] = 0;
  }

  AofQueues[3]= &que3;
  #endif

  for (;;)
  {
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    #ifdef RR


    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);
    }
  

    //RR end
    #endif

    #ifdef FCFS
    //FCFS start
  
    //!for FCFS, youre going to have to initialize a min ctime, a min proc, and loop, find the min ctime proc, acquire lock, run, release lock
    
    struct proc* minproc = 0;
    int ctimeflag = 0;

    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        if(ctimeflag == 0) //initialize mintime
        {
          minproc = p;
          ctimeflag = 1;
          continue;
        }
        else if(p->ctime < minproc->ctime)
        {
          release(&minproc->lock);
          minproc = p;
          continue;
        }
        
        release(&p->lock);
        
      }
      else
      {
        release(&p->lock);
      }
    }

    p = minproc;

    if (p != 0 && p->state == RUNNABLE)
    {
      // Switch to chosen process.  It is the process's job
      // to release its lock and then reacquire it
      // before jumping back to us.
      p->state = RUNNING;
      c->proc = p;
      swtch(&c->context, &p->context);

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;  
      release(&p->lock);
    }
  

    #endif

    //MLFQ start
    #ifdef MLFQ

    //!for MLFQ make array of length 4. init queue for each, thats your priority queues.

    //Go through entire list and put it in the queue 
    // printf("Tick %d\n", ticks);

    // for (p = proc; p < &proc[NPROC]; p++)
    // {
    //   if(p->state == RUNNABLE)
    //   { 
    //     printf("Process %d has priority %d\n", p->pid, p->priority);
    //   } 
    // }
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);

      if(p->state == RUNNABLE)
      {
        int exists = 0;
        // int pri = p->priority;
 
        //goign through all queues checking if process already exists
        //making sure to only consider whats bw front & rear
        for(int k = 0; k < 4; k++)
        {
          //if front < rear, just go from front to rear
          if(AofQueues[k]->front <= AofQueues[k]->rear) 
          {
            for(int d = AofQueues[k]->front; d <= AofQueues[k]->rear; d++)
            {
              //check if the same process already exists in any queue
              if(AofQueues[k]->arr[d] == p)
              {
                exists = 1;
                if(ticks - p->inserttime >= WAITTHRESHOLD)
                {
                  DeqyuElement(AofQueues[k], p);

                  // printf("Process %d has waited, moving to lower priority queue %d\n",  AofQueues[k]->arr[d]->pid, AofQueues[k]->arr[d]->priority - 1);
                  if(p->priority != 0)
                  {
                    p->inserttime = ticks;
                    Enqueue(AofQueues[--p->priority], p);
                    // printf("%d: %d demoted to %d\n", ticks, p->pid, p->priority);
                  }
                  else
                  {
                    p->inserttime = ticks;
                    Enqueue(AofQueues[p->priority], p);
                    // printf("%d: %d demoted to %d\n", ticks, p->pid, p->priority);
                  }
                }
              }
            }
          }
                
          //otherwise from front to size plus also 0 to rear
          else
          {
            for(int d = AofQueues[k]->front; d < NPROC; d++)
            {
              //check if the same process already exists in any queue
              if(AofQueues[k]->arr[d] == p)
              {
                exists = 1;
                if(ticks - AofQueues[k]->arr[d]->inserttime >= WAITTHRESHOLD)
                {
                  DeqyuElement(AofQueues[k], AofQueues[k]->arr[d]);
                  // printf("Process %d has waited, moving to lower priority queue %d\n",  AofQueues[k]->arr[d]->pid, AofQueues[k]->arr[d]->priority - 1);

                  if(AofQueues[k]->arr[d]->priority != 0)
                  {
                    p->inserttime = ticks;
                    Enqueue(AofQueues[--AofQueues[k]->arr[d]->priority], p);
                    // printf("%d: %d demoted to %d\n", ticks, AofQueues[k]->arr[d]->pid, AofQueues[k]->arr[d]->priority);
                  }
                  else
                  {
                    p->inserttime = ticks;
                    Enqueue(AofQueues[AofQueues[k]->arr[d]->priority], p);
                    // printf("%d: %d demoted to %d\n", ticks, AofQueues[k]->arr[d]->pid, AofQueues[k]->arr[d]->priority);
                  }
                }
              }
            }
            for(int d = 0; d <= AofQueues[k]->rear; d++)
            {
              //check if the same process already exists in any queue
              if(AofQueues[k]->arr[d] == p)
              {
                exists = 1;
                if(ticks - AofQueues[k]->arr[d]->inserttime >= WAITTHRESHOLD)
                {
                  DeqyuElement(AofQueues[k], AofQueues[k]->arr[d]);

                  // printf("Process %d has waited, moving to lower priority queue %d\n",  AofQueues[k]->arr[d]->pid, AofQueues[k]->arr[d]->priority - 1);

                  if(AofQueues[k]->arr[d]->priority != 0)
                  {
                    p->inserttime = ticks;
                    Enqueue(AofQueues[--AofQueues[k]->arr[d]->priority], p);
                    // printf("%d: %d demoted to %d\n", ticks, AofQueues[k]->arr[d]->pid, AofQueues[k]->arr[d]->priority);
                  }
                  else
                  {
                    p->inserttime = ticks;
                    Enqueue(AofQueues[AofQueues[k]->arr[d]->priority], p);
                    // printf("%d: %d demoted to %d\n", ticks, AofQueues[k]->arr[d]->pid, AofQueues[k]->arr[d]->priority);
                  }
                }
              }
            }
          }
        }
        if (exists == 0)
        {
          p->inserttime = ticks;
          // printf("%d: %d inserted to %d\n", ticks, p->pid, pri);
          Enqueue(AofQueues[p->priority], p);
        }          
        release(&p->lock);
      }
      else
      {
        release(&p->lock);
      }

    }

    // for (p = proc; p < &proc[NPROC]; p++)
    // {
    //   if(p->state == RUNNABLE)
    //   { 
    //     printf("Now Process %d has priority %d\n", p->pid, p->priority);
    //   } 
    // }

    //start from q0, when q0 is empty, move to lower priorities
    for(int w = 0; w < 4; w++)
    {
      if(!IsEmpty(AofQueues[w])) 
      { 
        uint starttick;       
        struct proc* pro;

        //process is runnable because its in the queue
        // printf("Dequeeuing: %d from %d, queue %d\n", AofQueues[w]->arr[AofQueues[w]->front]->pid, AofQueues[w]->arr[AofQueues[w]->front]->priority, w);
        pro = Dequeue(AofQueues[w]);
        
        //lock
        acquire(&pro->lock);

        starttick = ticks;      //current tick
        uint tslice = 0;

        if(w == 0)
        {
          tslice = 1;
        }
        else if(w == 1)
        {
          tslice = 3;
        }
        else if(w == 2)
        {
          tslice = 9;
        }
        else if(w == 3)
        {
          tslice = 15;
        }

        while(ticks - starttick <= tslice && pro->state == RUNNABLE)
        {

          //RUN
          // Switch to chosen process.  It is the process's job
          // to release its lock and then reacquire it
          // before jumping back to us.
          
          pro->state = RUNNING;
          c->proc = pro;
          swtch(&c->context, &pro->context);

          // Process is done running for now.
          // It should have changed its p->state before coming back.
          c->proc = 0;
        }

        release(&pro->lock); //locked beginning of for loop

        uint curtick;     //check how much time it took

        if(((curtick = ticks) - starttick) >= tslice) //process took longer than time slice
        {
          acquire(&pro->lock);

          if(pro->priority != 3)
          {
            if(pro->state == RUNNABLE)
            {
              pro->inserttime = ticks;
              pro->priority++;
              Enqueue(AofQueues[pro->priority], pro);   //increase priority & enqueue
              // printf("%d: %d inserted to %d\n", ticks, pro->pid, pro->priority);
            }
          }
          else
          {
            if(pro->state == RUNNABLE)
            {
              Enqueue(AofQueues[pro->priority], pro); 
              // printf("%d: %d inserted to %d\n", ticks, pro->pid, pro->priority);
            }
          }

          release(&pro->lock);
        }
        else
        {
          if(pro->state == RUNNABLE)
          {
            pro->inserttime = ticks;
            // printf("Process %d has been moved to queue %d at tick %d\n", pro->pid, w, ticks);
            // printf("%d: %d remains in %d\n", ticks, pro->pid, w);

            Enqueue(AofQueues[w], pro);   //enqueue in same queue
          }
          else
          {
            // printf("%d not runnable\n", pro->pid);
          }
        }
        break;
      }
    }

    //MLFQ end
    #endif  
  }
}
  // //RUNNING PROCESS ASSUMING YOU HAVE THE LOCK ACQUIRED
  // if (p != 0 && p->state == RUNNABLE)
  // {
  //   // Switch to chosen process.  It is the process's job
  //   // to release its lock and then reacquire it
  //   // before jumping back to us.
  //   p->state = RUNNING;
  //   c->proc = p;
  //   swtch(&c->context, &p->context);

  //   // Process is done running for now.
  //   // It should have changed its p->state before coming back.
  //   c->proc = 0;  
  //   release(&p->lock);
  // }

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void sched(void)
{
  int intena;
  struct proc *p = myproc();

  if (!holding(&p->lock))
    panic("sched p->lock");
  if (mycpu()->noff != 1)
    panic("sched locks");
  if (p->state == RUNNING)
    panic("sched running");
  if (intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first)
  {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();

  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
      {
        p->state = RUNNABLE;
      }
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == pid)
    {
      p->killed = 1;
      if (p->state == SLEEPING)
      {
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

void setkilled(struct proc *p)
{
  acquire(&p->lock);
  p->killed = 1;
  release(&p->lock);
}

int killed(struct proc *p)
{
  int k;

  acquire(&p->lock);
  k = p->killed;
  release(&p->lock);
  return k;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if (user_dst)
  {
    return copyout(p->pagetable, dst, src, len);
  }
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if (user_src)
  {
    return copyin(p->pagetable, dst, src, len);
  }
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
  static char *states[] = {
      [UNUSED] "unused",
      [USED] "used",
      [SLEEPING] "sleep ",
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (np = proc; np < &proc[NPROC]; np++)
    {
      if (np->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
        {
          // Found one.
          pid = np->pid;
          *rtime = np->rtime;
          *wtime = np->etime - np->ctime - np->rtime;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                   sizeof(np->xstate)) < 0)
          {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || p->killed)
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

void update_time()
{
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    {
      p->rtime++;
    }
    release(&p->lock);
  }
}

Queue InitQueue()
{
  //struct queue contains: 3 integers + 1 pointer
  struct Queue que;

  que.front = -1;
  que.rear = -1;
  que.size = NPROC;
  struct proc* arr[NPROC];
  que.arr = arr;
  for(int i = 0; i < NPROC; i++)
  {
    que.arr[i] = 0;
  }

  Queue q = &que;

  return q;
}

int IsEmpty(Queue q)
{
  return q->front == -1;
}

int IsFull(Queue q)
{
  return (q->rear + 1) % q->size == q->front;
}


void Enqueue(Queue q, struct proc* pro) 
{
  if (IsFull(q) || ((q->front == 0) && (q->rear == q->size-1)))
  {
    printf("Process queue is full\n");
    return;
  }
  if (IsEmpty(q))
  {
    q->front = 0;
    q->rear = 0;
  }
  else if(q->rear == q->size-1 && q->front != 0)
  {
    q->rear = 0;
  }
  else
  {
    q->rear++;
  }
  q->arr[q->rear] = pro;
}

struct proc* Dequeue(Queue q)
{
  struct proc * ret;

  if (IsEmpty(q))
  {
    printf("Process queue is empty\n");
    return 0;
  }
  if (q->front == q->rear)
  {
    ret = q->arr[q->front];
    q->front = -1;
    q->rear = -1;
      
  }
  else
  {
    ret = q->arr[q->front];
    q->front = (q->front + 1) % q->size;
  }
  return ret;
}

struct proc* DeqyuElement(Queue q, struct proc* pro)
{
  struct proc * ret;
  struct proc* deq;
  
  int oldfront = q->front;

  int curindex = 0;
  while(q->arr[curindex] != pro)
  {
    curindex++;
  }

  while(q->front != curindex)
  //while(q->front != curindex)
  {
    deq = Dequeue(q);
    Enqueue(q, deq);
  }
  ret = Dequeue(q);
  //while(!IsEmpty(q) && q->front != oldfront)
  while(q->front != oldfront)
  {
    deq = Dequeue(q);
    Enqueue(q, deq);
  }
  return ret;
}