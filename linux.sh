###
# @Project: 稻子网Linux工具箱
#!/bin/bash

#全局变量
down_url=https://github.com/xinua/huicheng/blob/855f19105dba3c0f3a478598ec4c3d2c7d3360ab
panel_path=/www/server/panel
tools_version='1.0.0'

#服务器性能测试
vpsxn() {
    curl -Lso- https://github.com/xinua/huicheng/blob/855f19105dba3c0f3a478598ec4c3d2c7d3360ab/bench.sh | bash
    back_home
}
#服务器回程测试
vpshc() {
    curl -Lso- https://github.com/xinua/huicheng/blob/855f19105dba3c0f3a478598ec4c3d2c7d3360ab/test.sh | bash
    back_home
}


main() {
    clear
    echo -e "

\e[1;32m
#=====================================================#
#  脚本名称:    稻子网Linux工具箱 v.${tools_version}          #
#  官方网站:    https://www.daozi.net/               #
#-----------------------------------------------------#            #
#--------------------[宝塔工具]-----------------------#
# (1)服务器性能测试                                   
# (2)服务器回程测试
# (a)更新脚本  (b)快捷启动  (c)封装工具  (0)退出脚本  #
#=====================================================#
\e[0m

	"
    read -p  "请输入需要输入的选项:" function
    case $function in
    1)
        vpsxn
        ;;
    2)
        vpshc
        ;;
    3)
        ubantu_bt
        ;;
    4)
        fedora_bt
        ;;
    5)
        updata_bt
        ;;
    6)
        mount_disk
        ;;
    7)
        centosmggz
        ;;
    x)
        uninstall_btpanel
        ;;
    z)
        count_checking
        ;;
    10)
        version=7.6.0
        degrade_btpanel
        ;;
    11)
        version=7.5.2
        degrade_btpanel
        ;;
    12)
        version=7.5.1
        degrade_btpanel
        ;;
    13)
        version=7.4.8
        degrade_btpanel
        ;;
    14)
        version=7.4.7
        degrade_btpanel
        ;;
    15)
        format_disk
        ;;
    16)
        kshhc
        ;;
    17)
        yum7
        ;;
    18)
        yum6
        ;;
    19)
        btdefault
        ;;
    20)
        yum_source
        ;;
    21)
        dns
        ;;
    22)
        cleaning_garbage
        ;;
    23)
        mandatory_landing
        ;;
    24)
        repair_environment
        ;;
    25)
        update_panel
        ;;
    26)
        stop_btpanel
        ;;
    27)
        vpsxn
        ;;
    28)
        bbryj
        ;;
    29)
        nfipjc
        ;;
    30)
        lmyact
        ;;
    a)
        new_version
        ;;
    b)
        quick_start
        ;;
    c)
        package_btpanel
        ;;
    *)
        delete
        ;;
    esac
}
main
