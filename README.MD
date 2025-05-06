<!-- created by AlphaNerd -->

#使用方法

### 赋予执行权限
```
chmod +x babylongenerator.sh
```

### 运行脚本：
```
sudo ./babylongenerator.sh
```

### 检查输出：
- babylon_wallets.csv（包含 10 个钱包的地址和助记词）。

- 示例 CSV 内容：
```
wallet_name,address,mnemonic
wallet_1,bbn1xyz...,word1 word2 word3 ...
wallet_2,bbn1abc...,word4 word5 word6 ...
...
```

再次生成钱包（可选）：
```
python3 generate_babylon_wallets.py
```
可编辑 generate_babylon_wallets.py 修改 num_wallets（钱包数量）或 output_file（输出文件名）。

