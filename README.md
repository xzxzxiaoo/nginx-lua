nginx+lua防攻击脚本
====

1、文件夹说明
===
conf
==
配置文件夹，白名单IP，白名单接口

redis.lua
==
库文件，连接redis使用

waf.lua
==
规则文件

2、使用说明
===
配置到nginx即可使用，需要搭建redis，NGINX需要支持lua脚本库