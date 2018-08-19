#!/bin/bash
#auther:nan
#compile mysql
#日志函数,用来记录安装和错误日志
log_head(){
	date_now="Time: `date +%Y%m%d%H%M%S` Function:  \033[32m $1 \033[0m"
	echo -e "\033[46;31m ***log*** \033[0m" &>>/compile.log
	if [[ -n $2 ]]
	then
		echo -e "${date_now}  Action: \033[32m $2 \033[0m" &>>/compile.log
	else
		echo -e  ${date_now}  &>>/compile.log
	fi
}
#退出函数
exit_func(){
	log_head "$1" "\033[42;31m \033[5m [ERROR]  \033[0m \033[0m \033[31m [异常终止退出!!] \033[0m " &>>/compile.log
	exit
}
#安装yum源函数需指定$1,为挂载路径
#yum_auto /mnt
yum_auto(){
        #install yum
        #挂载光盘本地yum源
        log_head "[yum_auto]" "[start]" 
        yum_bak=/repo_`date +%Y%m%d%H%M%S`.tar.gz.bak 
	log_head "[yum_auto]" "[开始备份yum文件]"  &>>/compile.log
	tar -czf  ${yum_bak} -C /etc/yum.repos.d . &>>/compile.log
        rm -f /etc/yum.repos.d/* &>>/compile.log
        umount /dev/sr0 &>>/compile.log
        mount /dev/sr0 $1 &>>/compile.log  || mkdir $1 &>>/compile.log  &&  mount /dev/sr0 $1 &>>/compile.log

cat <<eof>/etc/yum.repos.d/local.repo
[yumlocal]
name=yumlocal
baseurl=file://$1
enable=1
gpgcheck=0
eof
#判断yum源是否可以成功使用,不能则退出
if   yum clean all &>>/compile.log &&  yum makecache &>>/compile.log 
then	       
        log_head "[yum_auto]" "[success]" 
else 
	if  rm -rf /etc/yum.repos.d/* && tar -xf ${yum_bak} -C /etc/yum.repos.d
	then
       		log_head "[yum_auto]" "[已恢复当前yum备份]" 
	else
       		log_head "[yum_auto]" "[恢复备份失败,请手动恢复]" 
	fi
	exit_func [yum_auto] 
fi

}


#yum安装必要包 $1为参数,指定安装包
#gcc-c++ ncurses-devel
yum_install(){	
        log_head "[yum_install]" "[start]" 
	if rpm -q $1 &>>/compile.log
	then 
		log_head "[yum_install]" "[$1 已经安装]"
	elif yum -qy install $1 &>>/compile.log
	then	
        	log_head "[yum_install]" "[$1 安装成功]"	 
        	log_head "[yum_install]" "[success]" 
	else
		exit_func "[yum_install]"
	fi

}

#为其他主机创建ftp服务器
yum_create_ftp(){
	log_head "[yum_create_ftp]" "[start]"
	yum_install vsftpd
	if service vsftpd start
	then
		log_head "[yum_create_ftp]" "[copy yum wait.....]"
		if cp -R ${mount_cd}/* /var/ftp/pub
		then 
			log_head "[yum_create_ftp]" "[success]"
		else
			exit_func "[yum_create_ftp]"
		fi
	else
		exit_func "[yum_create_ftp]"
	fi

}

#检查mysql依赖包是否存在
#依赖包参数
check_depend(){
	if [[ -f /usr/local/src/$1 ]]	
	then
		log_head "[check_depend]" "[$1 存在]" 
	else
		exit_func "[check_depend] 文件 $1 不存在"
	fi
}
#编译安装cmake
compile_cmake(){
	log_head "[compile_cmake]" "[start]"
	cd /usr/local/src
	tar xf cmake-3.6.2.tar.gz
	cd cmake-3.6.2
	./bootstrap --prefix=/usr/local/cmake
	make
	if make install
	then
		log_head "[compile_cmake]" "[success]"
	else
		exit_func "[compile_cmake]"
	fi
}
#编译安装mysql
compile_mysql(){
	log_head "[compile_mysql]" "[start]"
	groupadd mysql
	useradd -g mysql mysql
	mkdir /mydata
	chown mysql:mysql /mydata
	chmod o= /mydata              #设置其他人没有任何权限
	
	cd /usr/local/src 
	tar xf mysql-5.7.16.tar.gz
	cd mysql-5.7.16
	/usr/local/cmake/bin/cmake .  -DCMAKE_INSTALL_PREFIX=/usr/local/mysql  -DMYSQL_DATADIR=/mydata -DWITH_BOOST=/usr/local/src  -DSYSCONFDIR=/etc  -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DWITH_PARTITION_STORAGE_ENGINE=1  -DEXTRA_CHARSETS=all  -DDEFAULT_CHARSET=utf8  -DDEFAULT_COLLATION=utf8_general_ci  -DWITH_DEBUG=0  -DMYSQL_MAINTAINER_MODE=0  -DWITH_SSL:STRING=bundled  -DWITH_ZLIB:STRING=bundled
	if make && make install
	then
		log_head "[compile_mysql]" "[success]"
		chown -R mysql:mysql /usr/local/mysql
		echo "export PATH=$PATH:/usr/local/mysql/bin" >>/etc/profile.d/mysql.sh
		bash                          #让新的PATH变量生效
		#加入服务列表并设置为开机自启
		cd /usr/local/mysql/support-files
		cp mysql.server  /etc/init.d/mysqld
		chmod +x /etc/init.d/mysqld
		chkconfig mysqld on
	else
		exit_func "[compile_mysql]"
	fi
}
#设置配置文件并初始化mysql
initial_mysql(){
	log_head "[initial_mysql]" "[start]"
cat<<eof>/etc/my.cnf
[mysql]
socket=/tmp/mysql.sock
 
[mysqld]
datadir=/mydata
socket=/tmp/mysql.sock
user=mysql
symbolic-links=0

[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/mydata/mysqld.pid
eof
	#初始化mysql
	if /usr/local/mysql/bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/mydata
	then
		log_head "[initial_mysql]" "[success]"
		service mysqld start
	else
		exit_func "[initial_mysql]"
	fi
}


main(){
	yum_auto /mnt
	yum_create_ftp
	yum_install gcc-c++
	yum_install ncurses-devel
	check_depend boost_1_59_0.tar.gz 
	check_depend cmake-3.6.2.tar.gz 
	check_depend mysql-5.7.16.tar.gz
	compile_cmake 
	compile_mysql
	initial_mysql
}

main  &>>/compile.log















