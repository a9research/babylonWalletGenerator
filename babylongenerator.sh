#!/bin/bash

# babylongenerator.sh
# 一键脚本：安装 Babylon CLI 及其依赖，生成 Python 脚本，批量生成钱包地址
# 已适配 root 用户运行

# 设置错误处理：任何命令失败则退出
set -e

# 日志函数
log() {
    echo "[INFO] $1"
}

# 错误函数
error() {
    echo "[ERROR] $1"
    exit 1
}

# 1. 安装依赖
log "安装系统依赖（Git、Make、GCC）..."
apt update
apt install -y git make gcc || error "无法安装系统依赖"

# 2. 安装 Go
GO_VERSION="1.21.13"
GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
log "检查并安装 Go ${GO_VERSION}..."

if ! command -v go >/dev/null 2>&1 || [[ $(go version | grep -o 'go[0-9]\.[0-9]*\.[0-9]*') < "go1.21" ]]; then
    log "下载 Go ${GO_VERSION}..."
    wget https://golang.org/dl/${GO_TAR} || error "无法下载 Go"
    
    log "安装 Go..."
    rm -rf /usr/local/go
    tar -C /usr/local -xzf ${GO_TAR} || error "无法解压 Go"
    rm ${GO_TAR}
    
    # 设置环境变量（针对 root 用户）
    log "配置 Go 环境变量..."
    echo "export PATH=\$PATH:/usr/local/go/bin" >> /root/.bashrc
    echo "export GOPATH=/root/go" >> /root/.bashrc
    echo "export PATH=\$PATH:\$GOPATH/bin" >> /root/.bashrc
    source /root/.bashrc
    
    # 立即应用环境变量到当前会话
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=/root/go
    export PATH=$PATH:$GOPATH/bin
else
    log "Go 已安装，版本：$(go version)"
fi

# 验证 Go
if ! command -v go >/dev/null 2>&1; then
    error "Go 安装失败或未正确添加到 PATH"
fi

# 3. 安装 Babylon CLI
BABYLON_VERSION="v1.0.0-rc.5"
log "安装 Babylon CLI ${BABYLON_VERSION}..."

if ! command -v babylond >/dev/null 2>&1; then
    log "克隆 Babylon 仓库..."
    rm -rf babylon
    git clone https://github.com/babylonlabs-io/babylon.git || error "无法克隆 Babylon 仓库"
    
    cd babylon
    git checkout ${BABYLON_VERSION} || error "无法切换到版本 ${BABYLON_VERSION}"
    
    log "构建并安装 babylond..."
    make install || error "无法构建 babylond"
    
    cd ..
    rm -rf babylon
else
    log "babylond 已安装，版本：$(babylond version)"
fi

# 验证 babylond
if ! command -v babylond >/dev/null 2>&1; then
    error "babylond 安装失败或未正确添加到 PATH"
fi

# 4. 创建 Python 脚本
PYTHON_SCRIPT="generate_babylon_wallets.py"
log "创建 Python 脚本 ${PYTHON_SCRIPT}..."

cat > ${PYTHON_SCRIPT} << 'EOF'
import subprocess
import json
import csv
import os

def generate_babylon_wallet(wallet_name):
    """
    使用 Babylon CLI 生成一个钱包，并返回地址和助记词
    """
    try:
        result = subprocess.run(
            ["babylond", "keys", "add", wallet_name, "--keyring-backend", "test", "--output", "json"],
            capture_output=True,
            text=True,
            check=True
        )
        wallet_info = json.loads(result.stdout)
        address = wallet_info.get("address", "")
        mnemonic = wallet_info.get("mnemonic", "")
        return {"name": wallet_name, "address": address, "mnemonic": mnemonic}
    except subprocess.CalledProcessError as e:
        print(f"生成钱包 {wallet_name} 失败: {e.stderr}")
        return None
    except json.JSONDecodeError:
        print(f"解析钱包 {wallet_name} 的输出失败")
        return None

def save_to_csv(wallets, output_file):
    """
    将钱包信息保存到 CSV 文件
    """
    fieldnames = ["wallet_name", "address", "mnemonic"]
    with open(output_file, mode="w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for wallet in wallets:
            writer.writerow({
                "wallet_name": wallet["name"],
                "address": wallet["address"],
                "mnemonic": wallet["mnemonic"]
            })

def main():
    num_wallets = 10  # 要生成的钱包数量
    output_file = "babylon_wallets.csv"  # 输出 CSV 文件名
    wallets = []
    for i in range(num_wallets):
        wallet_name = f"wallet_{i+1}"
        print(f"正在生成钱包: {wallet_name}")
        wallet_info = generate_babylon_wallet(wallet_name)
        if wallet_info:
            wallets.append(wallet_info)
    if wallets:
        save_to_csv(wallets, output_file)
        print(f"成功生成 {len(wallets)} 个钱包，已保存到 {output_file}")
    else:
        print("未生成任何钱包")

if __name__ == "__main__":
    main()
EOF

# 5. 检查 Python 环境
log "检查 Python 环境..."
if ! command -v python3 >/dev/null 2>&1; then
    log "安装 Python3..."
    apt install -y python3 || error "无法安装 Python3"
fi

# 6. 运行 Python 脚本
log "运行 Python 脚本生成钱包..."
python3 ${PYTHON_SCRIPT} || error "Python 脚本运行失败"

# 7. 清理和完成
log "安装和生成完成！"
log "钱包信息已保存到 babylon_wallets.csv"
log "可再次运行 'python3 ${PYTHON_SCRIPT}' 生成更多钱包"
log "请妥善保存 babylon_wallets.csv 中的助记词，切勿泄露！"