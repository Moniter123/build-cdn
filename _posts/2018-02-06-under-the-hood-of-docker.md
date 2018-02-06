---
layout:        post
title:         "Under the hood of Docker"
date:          2018-01-31 00:00:00
categories:    blog
excerpt:       "runc and rkt are container runtimes that power Docker. But what powers the container runtimes? Read on for a deeper look into containerization technology."     
preview:       /assets/img/under-the-hood-of-docker.png
fbimage:       /assets/img/under-the-hood-of-docker.png
twitterimage:  /assets/img/under-the-hood-of-docker.png
googleimage:   /assets/img/under-the-hood-of-docker.png
twitter_card:  summary_large_image
---

It may come as a surprise to you, but containers are not a technology. They don't exist. They are actually a result
of many different technologies built into the Linux kernel. Which ones you ask? Let's take a trip down memory lane...

## Traditional Linux resource limits

When I started out working on Linux, the only way to really limit how much resources could consume was `ulimit`, a
command that lets you set a per-process limit on things like the number of open files, etc.

Needless to say a *per process limit* is not very useful when dealing with modern day multi-tenant environments where
each user can run hundreds or even thousands of processes at the same time.

This used to be a major limitation and made general purpose hosting platforms an impossible thing to build.

## chroot: limiting filesystem access

Also a very ancient technology in Linux was a feature inherited from BSD called `chroot`, or change root. It did exactly
what the name implied, change the root filesystem. So in essence, a process could be *jailed* inside a directory and 
see that directory as its root filesystem, not knowing that there's a whole other world out there.

This is something that is widely supported in server software, even PHP-FPM can chroot itself into a directory,
preventing PHP applications from seeing outside the specified root. (Needless to say, a PHP application would need a 
number of files inside the chroot to operate properly, such as `/usr/share/zoneinfo`.)

If we were to write a little C program to demonstrate the functionality, it would look like this:

```c
chdir("/mnt/mychroot");
if (chroot("/mnt/mychroot") != 0) {
    perror("chroot /mnt/mychroot");
    return 1;
}
chdir("/");
``` 

Note the fact that the directory is changed to the directory before the chroot command, and to the root directory 
afterwards. This is done as a security precaution, because the chroot command itself does not release the current
directory pointer. In other words, if we didn't do that, it would be possible to still navigate the directory tree
outside the chroot. It is also customary to close all files (file handles) prior to the chroot to prevent accidentally
leaving a file from outside the root accessible to the program and breaking out of the chroot.

Let's expand that program a little and output the contents of the current directory:

```c
#include <stdio.h>
#include <unistd.h>
#include <dirent.h>

int main(void) {
    chdir("/mnt/mychroot");
    if (chroot("/mnt/mychroot") != 0) {
        perror("chroot /mnt/mychroot");
        return 1;
    }
    chdir("/");

    /* Read the current directory */
    DIR *dir;
    struct dirent *ent;
    if ((dir = opendir (".")) != NULL) {
        while ((ent = readdir (dir)) != NULL) {
            printf ("%s\n", ent->d_name);
        }
        closedir (dir);
    } else {
        perror ("");
        return 2;
    }
    return 0;
}
```

If you run this program on a completely empty directory, you will see that the directory is indeed empty. However,
it is important to note that the chroot syscall is only available to the user `root` and it is also not designed
to protect from a root user inside a chroot jail. It is therefore important that any program using the `chroot` system
call also switches to a non-root user after doing so.

## capabilities: making non-root users a little bit of root

Also a very important feature, originally envisioned as the POSIX IEEE 1003.1e standard, are capabilities. Many features
of the Linux kernel, such as opening a raw socket to send an ICMP echo packet (also known as ping), traditionally
required root privileges.

Needless to say, willy-nilly handing out root privileges to people or processes is a phenomenally bad idea. Luckily,
the Linux kernel offers a feature that is very similar to the aforementioned standard. Linux capabilities allow
a process running as root to switch to a non-root user, while still retaining some root features. Some of the more 
notable ones are:

- `CAP_CHOWN`: change the owner of any file.
- `CAP_KILL`: send a signal to any process (e.g. `SIGKILL`). Normally a process can only send a signal to a different process running under the same user.
- `CAP_NET_ADMIN`: manage network configuration, such as interfaces, firewalls, etc.
- `CAP_NET_RAW`: send a raw packet (e.g. ping).
- `CAP_NET_BIND_SERVICE`: open a port under 1024. (These are normally privileged ports only available to root.)
- `CAP_SETUID` and `CAP_SETGID`: change the user and group the process is running as.
- `CAP_SYS_CHROOT`: use the `chroot` system call mentioned above.
- `CAP_SYS_NICE`: change the scheduling priority of the current process.

If we want to try out these capabilities, we can use the `capsh` Linux command as root

```bash
capsh \
      --keep=1 \
      --user=janoszen \
      --caps=cap_net_raw+epi \
      -- -c "/bin/ping www.google.com"
```

If we want to accomplish this with in a C program, we can use the `capset` function.

## cgroups: process group resource limits

In 2008 Google engineers contributed an important feature to the Linux kernel: cgroups. These cgroups would let you set
resource limits not on a single process, but on a group of processes. This was an important step forward as it would
be the first time a customers programs, no matter how many processes they spawned, could be constrained to use their
allocated resources.

In fact, many modern Linux distributions expose cgroups in their filesystem under `/sys/fs/cgroup`:

```
cgroup on /sys/fs/cgroup/cpuset type cgroup (rw,nosuid,nodev,noexec,relatime,cpuset)
cgroup on /sys/fs/cgroup/memory type cgroup (rw,nosuid,nodev,noexec,relatime,memory)
cgroup on /sys/fs/cgroup/perf_event type cgroup (rw,nosuid,nodev,noexec,relatime,perf_event)
cgroup on /sys/fs/cgroup/net_cls,net_prio type cgroup (rw,nosuid,nodev,noexec,relatime,net_cls,net_prio)
cgroup on /sys/fs/cgroup/pids type cgroup (rw,nosuid,nodev,noexec,relatime,pids)
cgroup on /sys/fs/cgroup/cpu,cpuacct type cgroup (rw,nosuid,nodev,noexec,relatime,cpu,cpuacct)
cgroup on /sys/fs/cgroup/hugetlb type cgroup (rw,nosuid,nodev,noexec,relatime,hugetlb)
cgroup on /sys/fs/cgroup/blkio type cgroup (rw,nosuid,nodev,noexec,relatime,blkio)
cgroup on /sys/fs/cgroup/freezer type cgroup (rw,nosuid,nodev,noexec,relatime,freezer)
cgroup on /sys/fs/cgroup/devices type cgroup (rw,nosuid,nodev,noexec,relatime,devices)
cgroup on /sys/fs/cgroup/rdma type cgroup (rw,nosuid,nodev,noexec,relatime,rdma)
```

If we want to create a cgroup, we can again use a system call, or we can use the `cgcreate` command line utility:

```bash
cgcreate -g cpu,cpuacct:/my_group
```

As you can see, we not only supply the cgroups name, but also what types of limits we want to place. Now that we have
the chroup all set up, we can move a process into it:

```bash
cgclassify -g cpu,cpuset:/my_group 1234
```

Similarly, deletion can be done using the `cgdelete` command. If we were to limit the CPU cores this process can run on
to core 2, 3, and 4, we would do so like this:

```bash
echo "2,3,4" > /sys/fs/cgroup/cpuset/my_group/cpuset.cpus
```

A few notable examples of limits that can be set include:

- `cpuset.cpus`: sets the CPU cores the process can run on.
- `cpu.shares`: the amount of time slots this process gets on the CPU. CPU time is divided according to the shares.
- `cpu.rt_runtime_us`: the exact amount of microseconds of CPU time this process gets per time period.
- `cpu.rt_period_us`: the time period for the aforementioned limit.
- `memory.limit_in_bytes`: total memory available to the cgroup, including file cache.
- `memory.memsw.limit_in_bytes`: physical and virtual memory limit, excluding caches.
- `blkio.throttle.read_bps_device`: bytes per second limit on disk reads.
- `blkio.throttle.read_iops_device`: IO per second limit on disk reads.
- `blkio.throttle.write_bps_device`: bytes per second limit on disk writes.
- `blkio.throttle.write_iops_device`: IO per second limit on disk writes.

## Namespaces

This is where it begins to be really interesting. Namespaces have been around, but haven't really been useful until
until recently. But what are they?

Let's take an example. Normally, the Linux kernel would launch one network stack for one machine, so every process
has access to the same IP addresses, etc. However, using namespaces, it is able to launch a different network stack
for a certain process on, say, a virtual network card. So for all intents and purposes, that process does not see the
"standard" IP address of the computer running it, but rather has its own, dedicated network card.

This can, of course, not only be done for network, but rather for:

- cgroups
- user IDs (UID)
- network
- mount points
- interprocess communication (IPC)
- process IDs (PID)
- hostname (UTS)

Namespaces can be started and managed using the `clone()`, `setns()` és `unshare()` system calls. If we look at an easy
to demonstrate example, a process inside a PID namespace would not see any processes running outside of it:

```bash
$ newpid bash
$ ps auwfx
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0   4188    84 pts/0    S    09:20   0:00 newpid bash
root         2  2.6  0.6  22372  3436 pts/0    S    09:20   0:00 bash
root        14  0.0  0.2  18440  1196 pts/0    R+   09:20   0:00  \_ ps auwfx
```

If you inspect the namespaces above, we *almost* have all makings of the container system today.