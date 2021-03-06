RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
PLAIN='\033[0m'

about() {
	echo " +----------------------------------------------------------------------"
	echo " | 稻子网 Linux 一键测速脚本 "
	echo " +----------------------------------------------------------------------"
	echo " | Powered by SuperBench"
	echo " +----------------------------------------------------------------------"
	echo " | Intro：https://www.daozi.net"	
	echo " +----------------------------------------------------------------------"
}

cancel() {
	echo ""
	next;
	cleanup;
	echo " Done"
	exit
}

trap cancel SIGINT

benchinit() {
	echo " 正在安装相关依赖...";
	if [ -f /etc/redhat-release ]; then
	    release="centos"
	elif cat /etc/issue | grep -Eqi "debian"; then
	    release="debian"
	elif cat /etc/issue | grep -Eqi "ubuntu"; then
	    release="ubuntu"
	elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
	    release="centos"
	elif cat /proc/version | grep -Eqi "debian"; then
	    release="debian"
	elif cat /proc/version | grep -Eqi "ubuntu"; then
	    release="ubuntu"
	elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
	    release="centos"
	fi

	[[ $EUID -ne 0 ]] && echo -e "${RED}Error:${PLAIN} This script must be run as root!" && exit 1

	if  [ ! -e '/usr/bin/python' ]; then
	        echo " Installing Python ..."
	            if [ "${release}" == "centos" ]; then
	            		yum update > /dev/null 2>&1
	                    yum -y install python > /dev/null 2>&1
	                else
	                	apt-get update > /dev/null 2>&1
	                    apt-get -y install python > /dev/null 2>&1
	                fi
	        
	fi

	if  [ ! -e '/usr/bin/curl' ]; then
	        echo " Installing Curl ..."
	            if [ "${release}" == "centos" ]; then
	                yum update > /dev/null 2>&1
	                yum -y install curl > /dev/null 2>&1
	            else
	                apt-get update > /dev/null 2>&1
	                apt-get -y install curl > /dev/null 2>&1
	            fi
	fi

	if  [ ! -e '/usr/bin/wget' ]; then
	        echo " Installing Wget ..."
	            if [ "${release}" == "centos" ]; then
	                yum update > /dev/null 2>&1
	                yum -y install wget > /dev/null 2>&1
	            else
	                apt-get update > /dev/null 2>&1
	                apt-get -y install wget > /dev/null 2>&1
	            fi
	fi

	if  [ ! -e './speedtest-cli/speedtest' ]; then
		echo " Installing Speedtest-cli ..."
		wget --no-check-certificate -qO speedtest.tgz https://cdn.jsdelivr.net/gh/oooldking/script@master/speedtest_cli/ookla-speedtest-1.0.0-$(uname -m)-linux.tgz > /dev/null 2>&1
	fi
	mkdir -p speedtest-cli && tar zxvf speedtest.tgz -C ./speedtest-cli/ > /dev/null 2>&1 && chmod a+rx ./speedtest-cli/speedtest

	if  [ ! -e 'tools.py' ]; then
		echo " Installing tools.py ..."
		wget --no-check-certificate https://cdn.jsdelivr.net/gh/oooldking/script@master/tools.py > /dev/null 2>&1
	fi
	chmod a+rx tools.py

	sleep 5

	start=$(date +%s) 
	clear;
}

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

speed_test(){
	speedtest-cli/speedtest -p no --accept-license > $speedLog 2>&1
	is_upload=$(cat $speedLog | grep 'Upload')
	result_speed=$(cat $speedLog | awk -F ' ' '/Result/{print $3}')
	if [[ ${is_upload} ]]; then
		local REDownload=$(cat $speedLog | awk -F ' ' '/Download/{print $3}')
		local reupload=$(cat $speedLog | awk -F ' ' '/Upload/{print $3}')
		local relatency=$(cat $speedLog | awk -F ' ' '/Latency/{print $2}')

		temp=$(echo "$relatency" | awk -F '.' '{print $1}')
		if [[ ${temp} -gt 50 ]]; then
			relatency="(*)"${relatency}
		fi
		local nodeName=$2

		temp=$(echo "${REDownload}" | awk -F ' ' '{print $1}')
		if [[ $(awk -v num1=${temp} -v num2=0 'BEGIN{print(num1>num2)?"1":"0"}') -eq 1 ]]; then
			printf "${YELLOW}%-24s${GREEN}%-18s${RED}%-20s${SKYBLUE}%-12s${PLAIN}\n" " ${nodeName}" "${reupload} Mbit/s" "${REDownload} Mbit/s" "${relatency} ms"
		fi
	else
		local cerror="ERROR"
	fi
}

print_speedtest() {
	printf "%-24s%-18s%-20s%-12s\n" " 节点名称"      "上传速度"     "下载速度"     "延迟"
    speed_test '27377' '北京 电信'
    speed_test '29353' '武汉 电信'
	speed_test '29026' '成都 电信'
	speed_test '24447' '上海 联通'
	speed_test '26678' '广州 联通'
	speed_test '16192' '深圳 联通'
	speed_test '26850' '无锡 移动'
	speed_test '27249' '南京 移动'
	speed_test '16171' '福州 移动'
	

	rm -rf speedtest*
}

io_test() {
    (LANG=C dd if=/dev/zero of=test_file_$$ bs=512K count=$1 conv=fdatasync && rm -f test_file_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}

calc_disk() {
    local total_size=0
    local array=$@
    for size in ${array[@]}
    do
        [ "${size}" == "0" ] && size_t=0 || size_t=`echo ${size:0:${#size}-1}`
        [ "`echo ${size:(-1)}`" == "K" ] && size=0
        [ "`echo ${size:(-1)}`" == "M" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' / 1024}' )
        [ "`echo ${size:(-1)}`" == "T" ] && size=$( awk 'BEGIN{printf "%.1f", '$size_t' * 1024}' )
        [ "`echo ${size:(-1)}`" == "G" ] && size=${size_t}
        total_size=$( awk 'BEGIN{printf "%.1f", '$total_size' + '$size'}' )
    done
    echo ${total_size}
}

power_time() {

	result=$(smartctl -a $(result=$(cat /proc/mounts) && echo $(echo "$result" | awk '/data=ordered/{print $1}') | awk '{print $1}') 2>&1) && power_time=$(echo "$result" | awk '/Power_On/{print $10}') && echo "$power_time"
}

install_smart() {
	if  [ ! -e '/usr/sbin/smartctl' ]; then
		echo "Installing Smartctl ..."
	    if [ "${release}" == "centos" ]; then
	    	yum update > /dev/null 2>&1
	        yum -y install smartmontools > /dev/null 2>&1
	    else
	    	apt-get update > /dev/null 2>&1
	        apt-get -y install smartmontools > /dev/null 2>&1
	    fi      
	fi
}

ip_info(){
	isp=$(python tools.py geoip isp)
	as_tmp=$(python tools.py geoip as)
	asn=$(echo $as_tmp | awk -F ' ' '{print $1}')
	org=$(python tools.py geoip org)
	city=$(curl -s http://myip.ipip.net | xargs echo -n)
	
	echo -e " ASN & ISP    : ${SKYBLUE}$asn, $isp${PLAIN}"
	echo -e " IP所属机构   : ${YELLOW}$org${PLAIN}"
	echo -e " IP归属地     : ${SKYBLUE}$city${PLAIN}"

	rm -rf tools.py
}

virt_check(){
	if hash ifconfig 2>/dev/null; then
		eth=$(ifconfig)
	fi

	virtualx=$(dmesg) 2>/dev/null

    if  [ $(which dmidecode) ]; then
		sys_manu=$(dmidecode -s system-manufacturer) 2>/dev/null
		sys_product=$(dmidecode -s system-product-name) 2>/dev/null
		sys_ver=$(dmidecode -s system-version) 2>/dev/null
	else
		sys_manu=""
		sys_product=""
		sys_ver=""
	fi
	
	if grep docker /proc/1/cgroup -qa; then
	    virtual="Docker"
	elif grep lxc /proc/1/cgroup -qa; then
		virtual="Lxc"
	elif grep -qa container=lxc /proc/1/environ; then
		virtual="Lxc"
	elif [[ -f /proc/user_beancounters ]]; then
		virtual="OpenVZ"
	elif [[ "$virtualx" == *kvm-clock* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *KVM* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *QEMU* ]]; then
		virtual="KVM"
	elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
		virtual="VMware"
	elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
		virtual="Parallels"
	elif [[ "$virtualx" == *VirtualBox* ]]; then
		virtual="VirtualBox"
	elif [[ -e /proc/xen ]]; then
		virtual="Xen"
	elif [[ "$sys_manu" == *"Microsoft Corporation"* ]]; then
		if [[ "$sys_product" == *"Virtual Machine"* ]]; then
			if [[ "$sys_ver" == *"7.0"* || "$sys_ver" == *"Hyper-V" ]]; then
				virtual="Hyper-V"
			else
				virtual="Microsoft Virtual Machine"
			fi
		fi
	else
		virtual="Dedicated"
	fi
}

power_time_check(){
	echo -ne " Power time of disk   : "
	install_smart
	ptime=$(power_time)
	echo -e "${SKYBLUE}$ptime Hours${PLAIN}"
}

freedisk() {
	freespace=$( df -m . | awk 'NR==2 {print $4}' )
	if [[ $freespace == "" ]]; then
		$freespace=$( df -m . | awk 'NR==3 {print $3}' )
	fi
	if [[ $freespace -gt 1024 ]]; then
		printf "%s" $((1024*2))
	elif [[ $freespace -gt 512 ]]; then
		printf "%s" $((512*2))
	elif [[ $freespace -gt 256 ]]; then
		printf "%s" $((256*2))
	elif [[ $freespace -gt 128 ]]; then
		printf "%s" $((128*2))
	else
		printf "1"
	fi
}

print_io() {
	if [[ $1 == "fast" ]]; then
		writemb=$((128*2))
	else
		writemb=$(freedisk)
	fi
	
	writemb_size="$(( writemb / 2 ))MB"
	if [[ $writemb_size == "1024MB" ]]; then
		writemb_size="1.0GB"
	fi

	if [[ $writemb != "1" ]]; then
		echo -n " I/O 第一次测试( $writemb_size )   : "
		io1=$( io_test $writemb )
		echo -e "${YELLOW}$io1${PLAIN}"
		echo -n " I/O 第二次测试( $writemb_size )   : "
		io2=$( io_test $writemb )
		echo -e "${YELLOW}$io2${PLAIN}"
		echo -n " I/O 第三次测试( $writemb_size )   : "
		io3=$( io_test $writemb )
		echo -e "${YELLOW}$io3${PLAIN}"
		ioraw1=$( echo $io1 | awk 'NR==1 {print $1}' )
		[ "`echo $io1 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
		ioraw2=$( echo $io2 | awk 'NR==1 {print $1}' )
		[ "`echo $io2 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
		ioraw3=$( echo $io3 | awk 'NR==1 {print $1}' )
		[ "`echo $io3 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
		ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
		ioavg=$( awk 'BEGIN{printf "%.1f", '$ioall' / 3}' )
		echo -e " 平均 I/O 测试    : ${YELLOW}$ioavg MB/s${PLAIN}"
	else
		echo -e " ${RED}Not enough space!${PLAIN}"
	fi
}

print_system_info() {
	echo " +----------------------------------------------------------------------"
	echo " | 稻子网 Linux 一键测速脚本 "
	echo " +----------------------------------------------------------------------"
	echo " | Powered by SuperBench"
	echo " +----------------------------------------------------------------------"
	echo " | Intro：https://www.daozi.net"	
	echo " +----------------------------------------------------------------------"

	echo -e " CPU 型号     : ${SKYBLUE}$cname${PLAIN}"
	echo -e " CPU 核心数   : ${YELLOW}$cores Cores ${SKYBLUE}$freq MHz $arch${PLAIN}"
	echo -e " CPU 频率     : ${SKYBLUE}$corescache ${PLAIN}"
	echo -e " 操作系统     : ${SKYBLUE}$opsy ($lbit Bit) ${YELLOW}$virtual${PLAIN}"
	echo -e " 核心         : ${SKYBLUE}$kern${PLAIN}"
	echo -e " 整体空间     : ${SKYBLUE}$disk_used_size GB / ${YELLOW}$disk_total_size GB ${PLAIN}"
	echo -e " 内存         : ${SKYBLUE}$uram MB / ${YELLOW}$tram MB ${SKYBLUE}($bram MB Buff)${PLAIN}"
	echo -e " 总交换量     : ${SKYBLUE}$uswap MB / $swap MB${PLAIN}"
	echo -e " 正常运行时间 : ${SKYBLUE}$up${PLAIN}"
	echo -e " 加载平均值   : ${SKYBLUE}$load${PLAIN}"
	echo -e " TCP CC       : ${YELLOW}$tcpctrl${PLAIN}"
}

print_end_time() {
	echo -ne " 稻子网提醒您：测试完成！\n"
	end=$(date +%s) 
	time=$(( $end - $start ))
	if [[ $time -gt 60 ]]; then
		min=$(expr $time / 60)
		sec=$(expr $time % 60)
		echo -ne " 测试用时: ${min} 分 ${sec} 秒"
	else
		echo -ne " 测试用时: ${time} 秒"
	fi

	printf '\n'

	bj_time=$(curl -s http://cgi.im.qq.com/cgi-bin/cgi_svrtime)

	if [[ $(echo $bj_time | grep "html") ]]; then
		bj_time=$(date -u +%Y-%m-%d" "%H:%M:%S -d '+8 hours')
	fi
}

get_system_info() {
	cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
	freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	corescache=$( awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	tram=$( free -m | awk '/Mem/ {print $2}' )
	uram=$( free -m | awk '/Mem/ {print $3}' )
	bram=$( free -m | awk '/Mem/ {print $6}' )
	swap=$( free -m | awk '/Swap/ {print $2}' )
	uswap=$( free -m | awk '/Swap/ {print $3}' )
	up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days %d hour %d min\n",a,b,c)}' /proc/uptime )
	load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
	opsy=$( get_opsy )
	arch=$( uname -m )
	lbit=$( getconf LONG_BIT )
	kern=$( uname -r )

	disk_size1=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $2}' ))
	disk_size2=($( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $3}' ))
	disk_total_size=$( calc_disk ${disk_size1[@]} )
	disk_used_size=$( calc_disk ${disk_size2[@]} )

	tcpctrl=$( sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}' )

	virt_check
}

cleanup() {
	rm -f test_file_*
	rm -rf speedtest*
	rm -f tools.py
}

bench_all(){
	reset;
	about;
	benchinit;
	reset;
	next;
	get_system_info;
	print_system_info;
	ip_info;
	next;
	print_io;
	next;
	print_speedtest;
	next;
	print_end_time;
	next;
	cleanup;
}

speedLog="./speedtest.log"
true > $speedLog

bench_all;
