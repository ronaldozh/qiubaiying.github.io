---
layout:     post
title:      SpringBoot2.0学习笔记
subtitle:   记录出现的问题及知识点
date:       2018-8-8
author:     赵小恒
header-img: img/post-bg-coffee.jpeg
catalog: true
tags:
    - SpringMVC
    - Mybatis
---

### 第一天

以下源码解读：  
```
@Bean
public CommandLineRunner commandLineRunner(ApplicationContext ctx) {
    return args -> {

        System.out.println("Let's inspect the beans provided by Spring Boot:");

        String[] beanNames = ctx.getBeanDefinitionNames();
        Arrays.sort(beanNames);
        for (String beanName : beanNames) {
            System.out.println(beanName);
        }

    };
}
```
1、凡是子类及带属性、方法的类都注册Bean到Spring中，交给它管理；  
2、@Bean用在方法上，告诉Spring容器，你可以从下面这个方法中拿到一个Bean  
[参考博客](http://www.cnblogs.com/bossen/p/5824067.html)




 




















