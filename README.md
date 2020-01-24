# flashos

#### 介绍
我自己的操作系统，参考《操作系统真像还原》制作

#### 安装教程
1.准备一个虚拟机或者真机（我用的是virtual box）
2.虚拟机中安装一个32位的linux系统（我的是centos6.6 32位）
3.下载源码：git clone https://gitee.com/sunym1993/flashos
4.进入src目录，第一次可能没有out和target文件夹，执行：mkdir out target
5.执行运行指令：make brun