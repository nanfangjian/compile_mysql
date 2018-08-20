#ssh slave
script="/root/compile_mysql_slave.sh"
slave_list=($(cat ./slave_ip.txt))
for slave in ${slave_list[@]}
do
	expect -c "
        spawn  scp /root/compile_mysql_slave.sh ${slave}:/root/   
        expect {
            \"*(yes/no)?\"  {send \"yes\r\" ; exp_continue}
            \"*password:\"  {send \"1\r\" ; exp_continue} 
	}
	spawn scp /usr/local/src/boost_1_59_0.tar.gz ${slave}:/usr/local/src/
	expect {
            \"*(yes/no)?\"  {send \"yes\r\" ; exp_continue}
            \"*password:\"  {send \"1\r\" ; exp_continue} 
        }
	spawn scp /usr/local/src/cmake-3.6.2.tar.gz ${slave}:/usr/local/src/
        expect {
            \"*(yes/no)?\"  {send \"yes\r\" ; exp_continue}
            \"*password:\"  {send \"1\r\" ; exp_continue} 
        }
	spawn scp /usr/local/src/mysql-5.7.16.tar.gz ${slave}:/usr/local/src/
        expect {
            \"*(yes/no)?\"  {send \"yes\r\" ; exp_continue}
            \"*password:\"  {send \"1\r\" ; exp_continue} 
        }
	spawn  ssh ${slave}   bash ${script}
        expect {
            \"*(yes/no)?\"  {send \"yes\r\" ; exp_continue}
            \"*password:\"  {send \"1\r\" ; exp_continue} 
        }

	"
done
