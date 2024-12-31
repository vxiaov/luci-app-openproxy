# 目录说明

本目录用于存放：
- file类型 proxy-provider: 参考配置模板 template/proxy.yaml

用于存放自定义的配置文件，配置文件编辑器会读取当前目录下所有 .yaml 后缀配置文件。

## proxy-provider配置

完整配置示例请参考 template/proxy.yaml 文件。
代理组配置支持文件格式：
- yaml格式： 常规Clash支持的文件格式， 支持 vless/singbox 等类型规则。
- uri格式： 一行一个代理节点，方便用户配置。
- base64格式: 通常一行base64字符串，包含多个URI格式节点，通常适合制作为订阅配置。

