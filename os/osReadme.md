The /sbin/init program (also called init) coordinates the rest of the boot process and configures the environment for the user.
When the init command starts, it becomes the parent or grandparent of all of the processes that start up automatically on the system.
First, it runs the /etc/rc.d/rc.sysinit script, which sets the environment path, starts swap, checks the file systems, and executes all other steps required for system initialization.
After the init command has progressed through the appropriate rc directory for the runlevel, the /etc/inittab script forks an /sbin/mingetty process for each virtual console (login prompt)
Systemd is a widely used Linux software suite that also provides an init (also known as “initialization“), the first process that loads when you boot your Linux system.




```shell
stat /sbin/init
output:
File: /sbin/init -> ../lib/systemd/systemd
  Size: 22              Blocks: 8          IO Block: 4096   symbolic link

```
https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/4/html/reference_guide/s2-boot-init-shutdown-init#s2-boot-init-shutdown-init
https://ubuntushell.com/identify-the-init-system/
