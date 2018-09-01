#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================================
#   System Required:  CentOS (32bit/64bit)
#   Description:  A tool to auto-compile & install frpc on Linux
#   Author: HuayiSoftware
#===============================================================================================
program_name="frpc"
version="1.1.2"
str_program_dir="/usr/local/${program_name}"
program_init="/etc/init.d/${program_name}"
program_config_file="frpc.ini"
ver_file="/tmp/.frp_ver.sh"
program_version_link="https://soft.huayizhiyun.com/manage/frp/bash/version.sh"
str_install_shell=https://soft.huayizhiyun.com/manage/frp/bash/frpc/install-frpc.sh
shell_update(){
    fun_huayi "clear"
    echo "Check updates for shell..."
    remote_shell_version=`wget --no-check-certificate -qO- ${str_install_shell} | sed -n '/'^version'/p' | cut -d\" -f2`
    if [ ! -z ${remote_shell_version} ]; then
        if [[ "${version}" != "${remote_shell_version}" ]];then
            echo -e "${COLOR_GREEN}Found a new version,update now!!!${COLOR_END}"
            echo
            echo -n "Update shell ..."
            if ! wget --no-check-certificate -qO $0 ${str_install_shell}; then
                echo -e " [${COLOR_RED}failed${COLOR_END}]"
                echo
                exit 1
            else
                echo -e " [${COLOR_GREEN}OK${COLOR_END}]"
                echo
                echo -e "${COLOR_GREEN}Please Re-run${COLOR_END} ${COLOR_PINK}$0 ${huayi_action}${COLOR_END}"
                echo
                exit 1
            fi
            exit 1
        fi
    fi
}
fun_huayi(){
    local clear_flag=""
    clear_flag=$1
    if [[ ${clear_flag} == "clear" ]]; then
        clear
    fi
    echo ""
    echo "+---------------------------------------------------------+"
    echo "|                 frpc for Linux Server                   |"
    echo "+---------------------------------------------------------+"
    echo "|     A tool to auto-compile & install frpc on Linux      |"
    echo "+---------------------------------------------------------+"
    echo ""
}
fun_set_text_color(){
    COLOR_RED='\E[1;31m'
    COLOR_GREEN='\E[1;32m'
    COLOR_YELOW='\E[1;33m'
    COLOR_BLUE='\E[1;34m'
    COLOR_PINK='\E[1;35m'
    COLOR_PINKBACK_WHITEFONT='\033[45;37m'
    COLOR_GREEN_LIGHTNING='\033[32m \033[05m'
    COLOR_END='\E[0m'
}
# Check if user is root
rootness(){
    if [[ $EUID -ne 0 ]]; then
        fun_huayi
        echo "Error:This script must be run as root!" 1>&2
        exit 1
    fi
}
get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}
# Check OS
checkos(){
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        OS=CentOS
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        OS=Debian
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        OS=Ubuntu
    else
        echo "Not support OS, Please reinstall OS and retry!"
        exit 1
    fi
}
# Get version
getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else
        grep -oE  "[0-9.]+" /etc/issue
    fi
}
# CentOS version
centosversion(){
    local code=$1
    local version="`getversion`"
    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi
}
# Check OS bit
check_os_bit(){
    ARCHS=""
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
        ARCHS="amd64"
    else
        Is_64bit='n'
        ARCHS="386"
    fi
}
check_centosversion(){
if centosversion 5; then
    echo "Not support CentOS 5.x, please change to CentOS 6,7 or Debian or Ubuntu and try again."
    exit 1
fi
}
# Disable selinux
disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}
pre_install_packs(){
    local wget_flag=''
    local killall_flag=''
    local netstat_flag=''
    wget --version > /dev/null 2>&1
    wget_flag=$?
    killall -V >/dev/null 2>&1
    killall_flag=$?
    netstat --version >/dev/null 2>&1
    netstat_flag=$?
    if [[ ${wget_flag} -gt 1 ]] || [[ ${killall_flag} -gt 1 ]] || [[ ${netstat_flag} -gt 6 ]];then
        echo -e "${COLOR_GREEN} Install support packs...${COLOR_END}"
        if [ "${OS}" == 'CentOS' ]; then
            yum install -y wget psmisc net-tools
        else
            apt-get -y update && apt-get -y install wget psmisc net-tools
        fi
    fi
}
# Random password
fun_randstr(){
    strNum=$1
    [ -z "${strNum}" ] && strNum="16"
    strRandomPass=""
    strRandomPass=`tr -cd '[:alnum:]' < /dev/urandom | fold -w ${strNum} | head -n1`
    echo ${strRandomPass}
}
fun_get_version(){
    rm -f ${ver_file}
    if ! wget --no-check-certificate -qO ${ver_file} ${program_version_link}; then
        echo -e "${COLOR_RED}Failed to download version.sh${COLOR_END}"
    fi
    if [ -s ${ver_file} ]; then
        [ -x ${ver_file} ] && chmod +x ${ver_file}
        . ${ver_file}
        export FRPC_INIT="https://soft.huayizhiyun.com/manage/frp/bash/frpc/frpc.init"
    fi
    if [ -z ${FRP_VER} ] || [ -z ${FRPC_INIT} ] || [ -z ${huayi_download_url} ] || [ -z ${github_download_url} ]; then
        echo -e "${COLOR_RED}Error: ${COLOR_END}Get Program version failed!"
        exit 1
    fi
}
fun_getServer(){
    def_server_url="huayi"
    echo ""
    echo -e "Please select ${program_name} download url:"
    echo -e "[1].huayi (default)"
    echo -e "[2].github"
    read -p "Enter your choice (1, 2 or exit. default [${def_server_url}]): " set_server_url
    [ -z "${set_server_url}" ] && set_server_url="${def_server_url}"
    case "${set_server_url}" in
        1|[Hh][Uu][Aa][Yy][Ii])
            program_download_url=${huayi_download_url}
            ;;
        2|[Gg][Ii][Tt][Hh][Uu][Bb])
            program_download_url=${github_download_url}
            ;;
        [eE][xX][iI][tT])
            exit 1
            ;;
        *)
            program_download_url=${huayi_download_url}
            ;;
    esac
    echo "---------------------------------------"
    echo "Your select: ${set_server_url}"
    echo "---------------------------------------"
}
fun_getVer(){
    echo -e "Loading network version for ${program_name}, please wait..."
    program_latest_filename="frp_${FRP_VER}_linux_${ARCHS}.tar.gz"
    program_latest_file_url="${program_download_url}/v${FRP_VER}/${program_latest_filename}"
    if [ -z "${program_latest_filename}" ]; then
        echo -e "${COLOR_RED}Load network version failed!!!${COLOR_END}"
    else
        echo -e "${program_name} Latest release file ${COLOR_GREEN}${program_latest_filename}${COLOR_END}"
    fi
}
fun_download_file(){
    # download
    if [ ! -s ${str_program_dir}/${program_name} ]; then
        rm -fr ${program_latest_filename} frp_${FRP_VER}_linux_${ARCHS}
        if ! wget --no-check-certificate -q ${program_latest_file_url} -O ${program_latest_filename}; then
            echo -e " ${COLOR_RED}failed${COLOR_END}"
            exit 1
        fi
        tar xzf ${program_latest_filename}
        mv frp_${FRP_VER}_linux_${ARCHS}/frpc ${str_program_dir}/${program_name}
        rm -fr ${program_latest_filename} frp_${FRP_VER}_linux_${ARCHS}
    fi
    chown root:root -R ${str_program_dir}
    if [ -s ${str_program_dir}/${program_name} ]; then
        [ ! -x ${str_program_dir}/${program_name} ] && chmod 755 ${str_program_dir}/${program_name}
    else
        echo -e " ${COLOR_RED}failed${COLOR_END}"
        exit 1
    fi
}
function __readINI() {
 INIFILE=$1; SECTION=$2; ITEM=$3
 _readIni=`awk -F '=' '/\['$SECTION'\]/{a=1}a==1&&$1~/'$ITEM'/{print $2;exit}' $INIFILE`
echo ${_readIni}
}
# Check port
fun_check_port(){
    port_flag=""
    strCheckPort=""
    input_port=""
    port_flag="$1"
    strCheckPort="$2"
    if [ ${strCheckPort} -ge 1 ] && [ ${strCheckPort} -le 65535 ]; then
        checkServerPort=`netstat -ntulp | grep "\b:${strCheckPort}\b"`
        if [ -n "${checkServerPort}" ]; then
            echo ""
            echo -e "${COLOR_RED}Error:${COLOR_END} Port ${COLOR_GREEN}${strCheckPort}${COLOR_END} is ${COLOR_PINK}used${COLOR_END},view relevant port:"
            netstat -ntulp | grep "\b:${strCheckPort}\b"
            fun_input_${port_flag}_port
        else
            input_port="${strCheckPort}"
        fi
    else
        echo "Input error! Please input correct numbers."
        fun_input_${port_flag}_port
    fi
}
fun_check_number(){
    num_flag=""
    strMaxNum=""
    strCheckNum=""
    input_number=""
    num_flag="$1"
    strMaxNum="$2"
    strCheckNum="$3"
    if [ ${strCheckNum} -ge 1 ] && [ ${strCheckNum} -le ${strMaxNum} ]; then
        input_number="${strCheckNum}"
    else
        echo "Input error! Please input correct numbers."
        fun_input_${num_flag}
    fi
}
# input port
fun_input_server_port(){
    def_server_port="55555"
    echo ""
    echo -n -e "Please input ${program_name} ${COLOR_GREEN}server_port${COLOR_END} [1-65535]"
    read -p "(Default Server Port: ${def_server_port}):" serverport
    [ -z "${serverport}" ] && serverport="${def_server_port}"
    fun_check_port "bind" "${serverport}"
}
fun_input_admin_port(){
    def_admin_port="55580"
    echo ""
    echo -n -e "Please input ${program_name} ${COLOR_GREEN}admin_port${COLOR_END} [1-65535]"
    read -p "(Default admin_port: ${def_admin_port}):" input_admin_port
    [ -z "${input_admin_port}" ] && input_admin_port="${def_admin_port}"
    fun_check_port "admin" "${input_admin_port}"
}
fun_input_log_max_days(){
    def_max_days="30"
    def_log_max_days="3"
    echo ""
    echo -e "Please input ${program_name} ${COLOR_GREEN}log_max_days${COLOR_END} [1-${def_max_days}]"
    read -p "(Default log_max_days: ${def_log_max_days} day):" input_log_max_days
    [ -z "${input_log_max_days}" ] && input_log_max_days="${def_log_max_days}"
    fun_check_number "log_max_days" "${def_max_days}" "${input_log_max_days}"
}
fun_input_pool_count(){
    def_max_pool="50"
    def_pool_count="5"
    echo ""
    echo -e "Please input ${program_name} ${COLOR_GREEN}pool_count${COLOR_END} [1-${def_max_pool}]"
    read -p "(Default pool_count: ${def_pool_count}):" input_pool_count
    [ -z "${input_pool_count}" ] && input_pool_count="${def_pool_count}"
    fun_check_number "pool_count" "${def_max_pool}" "${input_pool_count}"
}
pre_install_huayi(){
    fun_huayi
    echo -e "Check your client setting, please wait..."
    disable_selinux
    if [ -s ${str_program_dir}/${program_name} ] && [ -s ${program_init} ]; then
        echo "${program_name} is installed!"
    else
        clear
        fun_huayi
        fun_get_version
        fun_getServer
        fun_getVer
        echo -e  "${COLOR_YELOW}Please input your client setting:${COLOR_END}"
        def_server_addr="0.0.0.0"
        read -p "Please input server_addr (Default: ${def_server_addr}):" set_server_addr
        [ -z "${set_server_addr}" ] && set_server_addr="${def_server_addr}"
        echo "${program_name} server_addr: ${set_server_addr}"
        echo ""
        fun_input_server_port
        [ -n "${input_port}" ] && set_server_port="${input_port}"
        echo "${program_name} server_port: ${set_server_port}"
        echo ""
        fun_input_admin_port
        [ -n "${input_port}" ] && set_admin_port="${input_port}"
        echo "${program_name} admin_port: ${set_admin_port}"
        echo ""
        def_admin_user="admin"
        read -p "Please input admin_user (Default: ${def_admin_user}):" set_admin_user
        [ -z "${set_admin_user}" ] && set_admin_user="${def_admin_user}"
        echo "${program_name} admin_user: ${set_admin_user}"
        echo ""
        def_admin_passwd=`fun_randstr 8`
        read -p "Please input admin_passwd (Default: ${def_admin_passwd}):" set_admin_passwd
        [ -z "${set_admin_passwd}" ] && set_admin_passwd="${def_admin_passwd}"
        echo "${program_name} admin_passwd: ${set_admin_passwd}"
        echo ""
        default_token=`fun_randstr 16`
        read -p "Please input token (Default: ${default_token}):" set_token
        [ -z "${set_token}" ] && set_token="${default_token}"
        echo "${program_name} token: ${set_token}"
        echo ""
        fun_input_pool_count
        [ -n "${input_number}" ] && set_pool_count="${input_number}"
        echo "${program_name} pool_count: ${set_pool_count}"
        echo ""
        echo "##### Please select log_level #####"
        echo "1: info (default)"
        echo "2: warn"
        echo "3: error"
        echo "4: debug"
        echo "#####################################################"
        read -p "Enter your choice (1, 2, 3, 4 or exit. default [1]): " str_log_level
        case "${str_log_level}" in
            1|[Ii][Nn][Ff][Oo])
                str_log_level="info"
                ;;
            2|[Ww][Aa][Rr][Nn])
                str_log_level="warn"
                ;;
            3|[Ee][Rr][Rr][Oo][Rr])
                str_log_level="error"
                ;;
            4|[Dd][Ee][Bb][Uu][Gg])
                str_log_level="debug"
                ;;
            [eE][xX][iI][tT])
                exit 1
                ;;
            *)
                str_log_level="info"
                ;;
        esac
        echo "log_level: ${str_log_level}"
        echo ""
        fun_input_log_max_days
        [ -n "${input_number}" ] && set_log_max_days="${input_number}"
        echo "${program_name} log_max_days: ${set_log_max_days}"
        echo ""
        echo "##### Please select log_file #####"
        echo "1: enable (default)"
        echo "2: disable"
        echo "#####################################################"
        read -p "Enter your choice (1, 2 or exit. default [1]): " str_log_file
        case "${str_log_file}" in
            1|[yY]|[yY][eE][sS]|[oO][nN]|[tT][rR][uU][eE]|[eE][nN][aA][bB][lL][eE])
                str_log_file=$str_program_dir"/frpc.log"
                str_log_file_flag="enable"
                ;;
            0|2|[nN]|[nN][oO]|[oO][fF][fF]|[fF][aA][lL][sS][eE]|[dD][iI][sS][aA][bB][lL][eE])
                str_log_file="/dev/null"
                str_log_file_flag="disable"
                ;;
            [eE][xX][iI][tT])
                exit 1
                ;;
            *)
                str_log_file=$str_program_dir"/frpc.log"
                str_log_file_flag="enable"
                ;;
        esac
        echo "log_file: ${str_log_file_flag}"
        echo ""
        echo "##### Please select tcp_mux #####"
        echo "1: enable (default)"
        echo "2: disable"
        echo "#####################################################"
        read -p "Enter your choice (1, 2 or exit. default [1]): " str_tcp_mux
        case "${str_tcp_mux}" in
            1|[yY]|[yY][eE][sS]|[oO][nN]|[tT][rR][uU][eE]|[eE][nN][aA][bB][lL][eE])
                set_tcp_mux="true"
                ;;
            0|2|[nN]|[nN][oO]|[oO][fF][fF]|[fF][aA][lL][sS][eE]|[dD][iI][sS][aA][bB][lL][eE])
                set_tcp_mux="false"
                ;;
            [eE][xX][iI][tT])
                exit 1
                ;;
            *)
                set_tcp_mux="true"
                ;;
        esac
        echo "tcp_mux: ${set_tcp_mux}"
        echo ""
        echo "============== Check your input =============="
        echo -e "You Server IP      : ${COLOR_GREEN}${set_server_addr}${COLOR_END}"
        echo -e "Server port        : ${COLOR_GREEN}${set_server_port}${COLOR_END}"
        echo -e "Admin port         : ${COLOR_GREEN}${set_admin_port}${COLOR_END}"
        echo -e "Admin user         : ${COLOR_GREEN}${set_admin_user}${COLOR_END}"
        echo -e "Admin password     : ${COLOR_GREEN}${set_admin_passwd}${COLOR_END}"
        echo -e "token              : ${COLOR_GREEN}${set_token}${COLOR_END}"
        echo -e "tcp_mux            : ${COLOR_GREEN}${set_tcp_mux}${COLOR_END}"
        echo -e "Pool count         : ${COLOR_GREEN}${set_pool_count}${COLOR_END}"
        echo -e "Log level          : ${COLOR_GREEN}${str_log_level}${COLOR_END}"
        echo -e "Log max days       : ${COLOR_GREEN}${set_log_max_days}${COLOR_END}"
        echo -e "Log file           : ${COLOR_GREEN}${str_log_file_flag}${COLOR_END}"
        echo "=============================================="
        echo ""
        echo "Press any key to start...or Press Ctrl+c to cancel"

        char=`get_char`
        install_program_server_huayi
    fi
}
# ====== install server ======
install_program_server_huayi(){
    [ ! -d ${str_program_dir} ] && mkdir -p ${str_program_dir}
    cd ${str_program_dir}
    echo "${program_name} install path:$PWD"

    echo -n "config file for ${program_name} ..."
# Config file
cat > ${str_program_dir}/${program_config_file}<<-EOF
# [common] is integral section
[common]
# A literal address or host name for IPv6 must be enclosed
# in square brackets, as in "[::1]:80", "[ipv6-host]:http" or "[ipv6-host%zone]:80"
server_addr = ${set_server_addr}
server_port = ${set_server_port}
# console or real logFile path like $str_program_dir/frpc.log
log_file = ${str_log_file}
# debug, info, warn, error
log_level = ${str_log_level}
log_max_days = ${set_log_max_days}
# auth token
token = ${set_token}
# set admin address for control frpc's action by http api such as reload
admin_addr = 127.0.0.1
admin_port = ${set_admin_port}
admin_user = ${set_admin_user}
admin_passwd = ${set_admin_passwd}
# connections will be established in advance, default value is zero
pool_count = ${set_pool_count}
# if tcp stream multiplexing is used, default is true, it must be same with frps
tcp_mux = ${set_tcp_mux}
# decide if exit program when first login failed, otherwise continuous relogin to frps
# default is true
login_fail_exit = false
# communication protocol used to connect to server
# now it supports tcp and kcp and websocket, default is tcp
protocol = tcp
EOF
    echo " done"

    echo -n "download ${program_name} ..."
    rm -f ${str_program_dir}/${program_name} ${program_init}
    fun_download_file
    echo " done"
    echo -n "download ${program_init}..."
    if [ ! -s ${program_init} ]; then
        if ! wget --no-check-certificate -q ${FRPC_INIT} -O ${program_init}; then
            echo -e " ${COLOR_RED}failed${COLOR_END}"
            exit 1
        fi
    fi
    [ ! -x ${program_init} ] && chmod +x ${program_init}
    echo " done"

    echo -n "setting ${program_name} boot..."
    [ ! -x ${program_init} ] && chmod +x ${program_init}
    if [ "${OS}" == 'CentOS' ]; then
        chmod +x ${program_init}
        chkconfig --add ${program_name}
    else
        chmod +x ${program_init}
        update-rc.d -f ${program_name} defaults
    fi
    echo " done"
    [ -s ${program_init} ] && ln -s ${program_init} /usr/bin/${program_name}
    ${program_init} start
    if [ -e  "/usr/local/directadmin/data/admin/services.status" ]; then
      sed -i '/frpc/d' /usr/local/directadmin/data/admin/services.status
      echo "frpc=ON" >> /usr/local/directadmin/data/admin/services.status
    fi
    fun_huayi
    #install successfully
    echo ""
    echo "Congratulations, ${program_name} install completed!"
    echo "=============================================="
    echo -e "You Server IP      : ${COLOR_GREEN}${set_server_addr}${COLOR_END}"
    echo -e "Bind port          : ${COLOR_GREEN}${set_server_port}${COLOR_END}"
    echo -e "Admin port         : ${COLOR_GREEN}${set_admin_port}${COLOR_END}"
    echo -e "token              : ${COLOR_GREEN}${set_token}${COLOR_END}"
    echo -e "tcp_mux            : ${COLOR_GREEN}${set_tcp_mux}${COLOR_END}"
    echo -e "Pool count         : ${COLOR_GREEN}${set_pool_count}${COLOR_END}"
    echo -e "Log level          : ${COLOR_GREEN}${str_log_level}${COLOR_END}"
    echo -e "Log max days       : ${COLOR_GREEN}${set_log_max_days}${COLOR_END}"
    echo -e "Log file           : ${COLOR_GREEN}${str_log_file_flag}${COLOR_END}"
    echo "=============================================="
    echo -e "${program_name} Admin          : ${COLOR_GREEN}http://${set_server_addr}:${set_admin_port}/${COLOR_END}"
    echo -e "Admin user         : ${COLOR_GREEN}${set_admin_user}${COLOR_END}"
    echo -e "Admin password     : ${COLOR_GREEN}${set_admin_passwd}${COLOR_END}"
    echo "=============================================="
    echo ""
    echo -e "${program_name} status manage : ${COLOR_PINKBACK_WHITEFONT}${program_name}${COLOR_END} {${COLOR_GREEN}start|stop|restart|status|config|version${COLOR_END}}"
    echo -e "Example:"
    echo -e "  start: ${COLOR_PINK}${program_name}${COLOR_END} ${COLOR_GREEN}start${COLOR_END}"
    echo -e "   stop: ${COLOR_PINK}${program_name}${COLOR_END} ${COLOR_GREEN}stop${COLOR_END}"
    echo -e "restart: ${COLOR_PINK}${program_name}${COLOR_END} ${COLOR_GREEN}restart${COLOR_END}"
    exit 0
}
############################### configure ##################################
configure_program_server_huayi(){
    if [ -s ${str_program_dir}/${program_config_file} ]; then
        vi ${str_program_dir}/${program_config_file}
    else
        echo "${program_name} configuration file not found!"
        exit 1
    fi
}
############################### uninstall ##################################
uninstall_program_server_huayi(){
    fun_huayi
    if [ -s ${program_init} ] || [ -s ${str_program_dir}/${program_name} ] ; then
        echo "============== Uninstall ${program_name} =============="
        str_uninstall="n"
        echo -n -e "${COLOR_YELOW}You want to uninstall?${COLOR_END}"
        read -p "[y/N]:" str_uninstall
        case "${str_uninstall}" in
        [yY]|[yY][eE][sS])
        echo ""
        echo "You select [Yes], press any key to continue."
        str_uninstall="y"
        char=`get_char`
        ;;
        *)
        echo ""
        str_uninstall="n"
        esac
        if [ "${str_uninstall}" == 'n' ]; then
            echo "You select [No],shell exit!"
        else
            checkos
            ${program_init} stop
            if [ "${OS}" == 'CentOS' ]; then
                chkconfig --del ${program_name}
            else
                update-rc.d -f ${program_name} remove
            fi
            rm -f ${program_init} /var/run/${program_name}.pid /usr/bin/${program_name}
            rm -fr ${str_program_dir}
            if [ -e  "/usr/local/directadmin/data/admin/services.status" ]; then
              sed -i '/frpc/d' /usr/local/directadmin/data/admin/services.status
            fi
            echo "${program_name} uninstall success!"
        fi
    else
        echo "${program_name} Not install!"
    fi
    exit 0
}
clear
strPath=`pwd`
rootness
fun_set_text_color
checkos
check_centosversion
check_os_bit
pre_install_packs
shell_update
# Initialization
action=$1
[  -z $1 ]
case "$action" in
install)
    pre_install_huayi 2>&1 | tee /root/${program_name}-install.log
    ;;
config)
    configure_program_server_huayi
    ;;
uninstall)
    uninstall_program_server_huayi 2>&1 | tee /root/${program_name}-uninstall.log
    ;;
*)
    fun_huayi
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall|config}"
    RET_VAL=1
    ;;
esac