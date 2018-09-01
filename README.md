# bash
my bash

Install FRP Server
wget --no-check-certificate https://raw.githubusercontent.com/hitsword/bash/master/frp/frps/install-frps.sh
chmod +x install-frps.sh
./install-frps.sh install

Uninstall FRP Server
./install-frps.sh uninstall

Install FRP Client
wget --no-check-certificate https://raw.githubusercontent.com/hitsword/bash/master/frp/frpc/install-frpc.sh
chmod +x install-frpc.sh
./install-frpc.sh install

Uninstall FRP Client
./install-frpc.sh uninstall