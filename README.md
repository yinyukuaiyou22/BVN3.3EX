# BVN 死神 vs 火影 V3.3EX

ActionScript 3 / AIR 格斗游戏，以手机端为主，PC 端可编译调试。本仓库只放源码与文档，安装包与素材走 Release。

## 一、资源可以不内置进安装包

安装包里的资源只是回退。把资源放到手机的这个目录，游戏会优先读外置文件：

    /storage/emulated/0/Android/media/air.com.bvn.yy798/BVN/assets/

里面按正常格式建这几个子目录：

    config    配置文件
    fighter   人物
    map       地图
    face      头像
    bgm       背景音乐
    sounds    音效

规矩只有三条：

1 名字和配置里写的一致，扩展名不要改；
2 外置有就用外置，外置没有才用安装包里的；
3 想确认到底读了哪一个，看日志里的 EXT-RESOLVE，external 是外置，apk-fallback 是内置。

配置文件里写了某项资源，也可以把它放到外置目录，安装包内不够塞的同样往外面放。详细目录与字段见 docs 第二章。

## 二、文档

用户向文档在 docs 目录，按章节分开读：

    docs/README.md                      文档总目录
    docs/01-安装与发布说明.md            怎么装、怎么更新、发行版是什么
    docs/02-外置资源目录与配置.md         每个配置文件的字段与规则
    docs/03-人物子框写法与触发.md         人物子框怎么配、怎么触发
    docs/04-常见问题.md                  人物不出现、地图不出现、黑屏怎么查

开发向文档在 doc 目录，入口是 doc/README.md。

## 三、编译与打包

    build.bat                 编译出 tools/Test/launch.swf
    tools/script/pack_only.bat  只编译加打包，不碰任何设备
    tools/script/debug.bat      编译后用 adl 在本机跑

签名密码从环境变量读，不写进脚本：

    set BVN_KEYSTORE_PASS=你的密码

## 四、发布

Release 里放两样东西：安装包，以及给作者看的资源模板。仓库本身不提交安装包、不提交资源二进制。

无资源发行版的意思是：安装包里只留主程序、配置和启动必需的基础资源，人物、地图、音乐这些放到上面说的外置目录，避免安装包过大。
