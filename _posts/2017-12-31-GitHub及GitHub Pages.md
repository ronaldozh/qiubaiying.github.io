---
layout:     post
title:      GitHub及GitHub Pages
subtitle:   github注册、git安装、github pages使用
date:       2017-12-31
author:     赵小恒
header-img: img/post-bg-coffee.jpeg
catalog: true
tags:
    - git
    - github
    - jekyll	
---

### 1、注册GitHub

#### 1.1第1步
![](http://p1tx4k6f5.bkt.clouddn.com/1.png)

#### 1.2第2步
![](http://p1tx4k6f5.bkt.clouddn.com/2.png)

#### 1.3第3步
![](http://p1tx4k6f5.bkt.clouddn.com/3.png)

#### 1.4第4步
![](http://p1tx4k6f5.bkt.clouddn.com/4.png)

#### 1.5第5步
![](http://p1tx4k6f5.bkt.clouddn.com/5.png)

#### 1.6第6步
![](http://p1tx4k6f5.bkt.clouddn.com/6.png)

#### 1.7第7步
![](http://p1tx4k6f5.bkt.clouddn.com/7.png)

#### 1.8第8步
![](http://p1tx4k6f5.bkt.clouddn.com/8.png)

#### 1.9第9步
![](http://p1tx4k6f5.bkt.clouddn.com/9.png)

#### 1.10第10步
![](http://p1tx4k6f5.bkt.clouddn.com/10.png)

#### 1.11第11步
![](http://p1tx4k6f5.bkt.clouddn.com/11.png)

#### 1.12第12步
![](http://p1tx4k6f5.bkt.clouddn.com/12.png)

### 2、安装Git
#### 2.1第1步
![](http://p1tx4k6f5.bkt.clouddn.com/gitInstall1.png)

#### 2.2第2步
![](http://p1tx4k6f5.bkt.clouddn.com/gitInstall2.png)

#### 2.3第3步
![](http://p1tx4k6f5.bkt.clouddn.com/gitInstall3.png)

#### 2.4第4步
![](http://p1tx4k6f5.bkt.clouddn.com/gitInstall4.png)

#### 2.5第5步
![](http://p1tx4k6f5.bkt.clouddn.com/gitInstall5.png)

#### 2.6第6步
![](http://p1tx4k6f5.bkt.clouddn.com/gitInstall6.png)

#### 2.7第7步
![](http://p1tx4k6f5.bkt.clouddn.com/gitInstall7.png)

#### 2.8第8步
![](http://p1tx4k6f5.bkt.clouddn.com/gitInstall8.png)

#### 2.9第9步
![](http://p1tx4k6f5.bkt.clouddn.com/gitInstall9.png)

#### 2.10第10步
![](http://p1tx4k6f5.bkt.clouddn.com/gitInstall10.png)

### 3、GitHub Pages操作
#### 3.1快速搭建一个GitHub Pages

`下方出现的sanhaowuai都是自己的github账户名称`

+ 1、在github上创建一个repository，仓库名称为sanhaowuai.github.io
+ 2、打开任意地方右键鼠标，选择Git Bash Here
+ 3、输入`ssh-keygen -t rsa -C "sanhaowuai@163.com"`
+ 4、连续三次回车，创建无密码ssh
+ 5、去C盘下依次点开 /用户/zhaoheng/.ssh,然后复制id_rsa.pub中的内容到github中的秘钥配置中。github的公钥配置打开如下图：
![](http://p1tx4k6f5.bkt.clouddn.com/gitpages1.png)
![](http://p1tx4k6f5.bkt.clouddn.com/gitpages2.png)
![](http://p1tx4k6f5.bkt.clouddn.com/gitpages3.png)
+ 6、验证是否连接Github,输入`ssh -T git@github.com`，若出现没有建立的错误输入yes 
+ 7、配置本地账户密码，输入：`git config --global user.name "sanhaowuai"`，回车，再次输入
`git config --global user.email "sanhaowuai@163.com"`
+ 8、添加远程地址，输入：  
`git remote add sanhaowuai git@github.com:sanhaowuai/github.io.git`
+ 9、创建一个文件夹，例如我在d盘下创建GitHub，然后在git的命令框里输入：`cd /d/Github`,再输入`git init`
+ 10、输入`git clone https://github.com/sanhaowuai/sanhaowuai.github.io.git`，  
**ps:https的地址为项目的地址**
+ 11、将下载好的jekyll模板复制到下载好的本地sanhaowuai.github.io文件夹中
+ 12、输入`cd /d/Github/sanhaowuai.giuhub.io`,依次输入`git add .` ，`git commit -m "提交"`，`git push -u sanhaowuai master`
+ 12、访问sanhaowuai.github.io，即可看到博客主页

#### 3.2Git连接多个GitHub账号
+ 1、`ssh-keygen -t rsa -C "sanhaowuai@163.com"`
+ 2、连续三次回车
+ 3、`ssh-keygen -t rsa -C "947213515@163.com"`
+ 4、回车后出现Generating public/private rsa key pair.Enter file in which to save the key (/c/Users/zhaoheng/.ssh/id_rsa):
输入：`/c/Users/zhaoheng/.ssh/id_rsa_ronaldozh`
+ 5、再连续点击两次enter回车
+ 6、因为默认只读取id_rsa，为了让SSH识别新的私钥，需将其添加到SSH agent中：`ssh-add ~/.ssh/id_rsa_ronaldozh`
如果出现**Could not open a connection to your authentication agent**的错误，就试着用以下命令：
`ssh-agent bash`
`ssh-add ~/.ssh/id_rsa_ronaldozh`
+ 7.在~/.ssh目录下找到config文件，如果没有就创建：`touch config`    
然后修改config配置如下：
{% highlight java %}
# Default github user(sanhaowuai@mail.com)
 Host github.com
 HostName github.com
 User git
 IdentityFile C:/Users/zhaoheng/.ssh/id_rsa
 
 # second user(ronaldozh@mail.com)
 Host github2
 HostName github.com
 User git
 IdentityFile C:\Users\zhaoheng\.ssh\id_rsa2_ronaldozh
{% endhighlight %} 
+ 8.将id_rsa.pub与id_rsa_ronaldozh.pub分别复制到相应的github公钥中
+ 9.测试：`ssh -T git@github.com`，
`ssh -T git@github2`
+ 10.修改远程仓库别名 `git remote add sanhaowuai 项目地址`，`git remote add ronaldozh 项目地址`












 




















