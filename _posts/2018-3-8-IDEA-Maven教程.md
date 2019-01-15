---
layout:     post
title:      IDEA-Maven教程
subtitle:   教程出现的问题及解决方法
date:       2018-3-8
author:     赵小恒
header-img: img/post-bg-coffee.jpeg
catalog: true
tags:
    - maven
    - jetty
---

### 1、Maven教程及配置本地Maven

[配置教程—优先考虑](https://www.cnblogs.com/phpdragon/p/7216626.html)

[Maven教程博客](http://www.cnblogs.com/Brake/p/maven_pom_optimization.html) 

若想通过cmd窗口，在项目目录下启动jetty,例如：在项目web-app目录下，输入mvn jetty:run,则访问的自带的maven,
若想访问本地仓库，则在c盘的.m2文件夹中的setting.xml文件中加入  
`<localRepository>D:\javasoft\maven\apache-maven-3.5.2\repository</localRepository>`  
指向本地仓库。

### 2、配置jetty插件

首先新建一个maven项目，然后在pom文件中配置maven-jetty-plugin插件，如下是一个完整的pom文件：

```
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.zh.kmpp</groupId>
  <artifactId>web_app</artifactId>
  <packaging>war</packaging>
  <version>1.0-SNAPSHOT</version>
  <name>web_app Maven Webapp</name>
  <url>http://maven.apache.org</url>
  <dependencies>
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>3.8.1</version>
      <scope>test</scope>
    </dependency>
      <dependency>
          <groupId>org.apache.geronimo.specs</groupId>
          <artifactId>geronimo-servlet_3.0_spec</artifactId>
          <version>1.0</version>
      </dependency>

  </dependencies>
  <build>
    <finalName>web_app</finalName>
      <pluginManagement>
          <!--配置Jetty-->
           <plugins>
                <plugin>
                    <!--<groupId>org.mortbay.jetty</groupId>
                    <artifactId>maven-jetty-plugin</artifactId>-->
                    <groupId>org.mortbay.jetty</groupId>
                    <artifactId>maven-jetty-plugin</artifactId>
                    <version>6.1.26</version>
                    <configuration>
                        <connectors>
                            <connector implementation="org.mortbay.jetty.nio.SelectChannelConnector">
                                <port>8080</port>
                            </connector>
                        </connectors>
                        <scanIntervalSeconds>10</scanIntervalSeconds>
                    </configuration>
                </plugin>
           </plugins>
      </pluginManagement>
  </build>
</project>
```
然后编辑调试配置，如下图：
![](https://raw.githubusercontent.com/sanhaowuai/picBed/master/pastPic/maven_jetty_1.jpg)
在弹出的配置窗口中添加一个Maven配置，并输入运行信息，如下图：
![](https://raw.githubusercontent.com/sanhaowuai/picBed/master/pastPic/maven_jetty_2.jpg)
保存之后，在右侧MavenProjects中双击刚配置的jetty即可启动服务器。
![](https://raw.githubusercontent.com/sanhaowuai/picBed/master/pastPic/maven_jetty_3.jpg)

### 3、利用intellij idea创建maven 多模块项目

#### 3.1 发布war包及jetty访问

1.需要点击右侧MavenProjects中的父module中的Lifecycle->package  
2.父module中的Lifecycle->package->install,后即可使用jetty插件发布，若使用tomcat无需install



 




















