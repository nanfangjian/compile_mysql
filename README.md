# compile_mysql
编译安装mysql 主+从 全自动完成
----compile_mysql_master.sh
    ----主要用于本机yum源的创建
    ----创建ftp yum源
    ----编译安装本机mysql
----compile_mysql_slave.sh
    ----创建ftp的yum源
    ----编译安装从机mysql
----slave.sh
    ----使用expect来进行交互输入
    ----使用scp来进行文件拷贝
    ----通过读取slave_ip.txt来对从机分配任务
----slave_ip.sh
    ----使用空格来分隔 slave ip
