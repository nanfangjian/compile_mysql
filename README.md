# compile_mysql
编译安装mysql 主+从 全自动完成,<\br>
----compile_mysql_master.sh<\br>
    ----主要用于本机yum源的创建<\br>
    ----创建ftp yum源<\br>
    ----编译安装本机mysql<\br>
----compile_mysql_slave.sh<\br>
    ----创建ftp的yum源<\br>
    ----编译安装从机mysql<\br><\br
----slave.sh<\br
    ----使用expect来进行交互输入<\br>
    ----使用scp来进行文件拷贝<\br>
    ----通过读取slave_ip.txt来对从机分配任务<\br>
----slave_ip.sh<\br>
    ----使用空格来分隔 slave ip<\br>
