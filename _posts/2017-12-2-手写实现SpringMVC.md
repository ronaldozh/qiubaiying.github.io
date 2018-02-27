---
layout:     post
title:      手写实现SpringMVC
subtitle:   剖析IOC及URL地址映射
date:       2017-12-2
author:     赵小恒
header-img: img/post-bg-debug.png
catalog: true
tags:
    - spring
    - Properties
---

### 1、知识点介绍
```
1 自定义注解（@Controller，@RequestParam，@AutoWired等）的使用
2 反射（使用IOC给AutoWired赋值）
3 请求分发、解析
4 其他
```
### 2、创建Java Web项目

#### 2.1 创建一个空的项目

#### 2.2 添加一个入口Servlet

{% highligh ruby %}
package com.zhaoheng.mvc;  
  
import javax.servlet.ServletConfig;  
import javax.servlet.ServletException;  
import javax.servlet.http.HttpServlet;  
import javax.servlet.http.HttpServletRequest;  
import javax.servlet.http.HttpServletResponse;  
import java.io.IOException;  
  
/** 
 * Created by wuwf on 17/6/28. 
 * 入口Sevlet 
 */  
public class DispatcherServlet extends HttpServlet {  
  
    @Override  
    public void init(ServletConfig config) throws ServletException {  
        System.out.println("我是初始化方法");  
    }  
  
    @Override  
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {  
        doPost(req, resp);  
    }  
  
    @Override  
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {  
        out(resp, "请求到我啦");  
    }  
  
    private void out(HttpServletResponse response, String str) {  
        try {  
            response.setContentType("application/json;charset=utf-8");  
            response.getWriter().print(str);  
        } catch (IOException e) {  
            e.printStackTrace();  
        }  
    }  
  
} 
{% endhighlight %}   
这是一个普通的Servlet，里面包含初始化和get、post方法，方便起见，我们让get也走post方法，并在post里输出一句话。

#### 2.3 配置web.xml

如果想让Servlet生效，能处理web请求，需要在web.xml做配置。

{% highligh ruby %}
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-app_3_1.xsd"
         version="3.1">
    <servlet>
        <servlet-name>dispatchServlet</servlet-name>
        <servlet-class>com.zhaoheng.mvc.DispatcherServlet</servlet-class>
        <load-on-startup>1</load-on-startup>
    </servlet>
    <servlet-mapping>
        <servlet-name>dispatchServlet</servlet-name>
        <url-pattern>/*</url-pattern>
    </servlet-mapping>
</web-app>
{% endhighlight %}   
我们配置该Servlet拦截/*也就是所有的请求，那么发起的所有web请求，都将进入DispatcherServlet，之后我们通过分析请求的url，
来决定由哪个Controller来处理请求。这也是Struts2和SpringMVC不同的一个地方，Struts2是通过filter来拦截所有请求，SpringMVC是通过Servlet。  
上面就已经完成了一个Servlet的配置，就可以响应web请求了。这也是大部分学JavaWeb开发的第一课。
部署到Tomcat，启动，访问任何一个url，可以看到post里输出的提示。

下一部分-自定义注解，和给注解赋值。

### 3、自定义注解及反射赋值

项目文件结构
![](http://p4suof94f.bkt.clouddn.com/springmvc_1.jpg)

#### 3.1 先来创建自定义注解

注意，根据不同的注解使用的范围来定义@Target，譬如Controller，Service能注解到类，RequestMapping能注解到类和方法，AutoWired只能注解到属性。

Autowired

{% highligh ruby %}
package com.zhaoheng.mvc.annotation;

import java.lang.annotation.*;

@Target({ElementType.FIELD})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Autowired {

    String value() default "";
}
{% endhighlight %}

Controller

{% highligh ruby %}
package com.zhaoheng.mvc.annotation;

import java.lang.annotation.*;
@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Controller {

    String value() default "";
}
{% endhighlight %}

RequestMapping

{% highligh ruby %}
package com.zhaoheng.mvc.annotation;

import java.lang.annotation.*;

@Target({ElementType.TYPE, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface RequestMapping {
    String value() default "";
}
{% endhighlight %}

RequestParam

{% highligh ruby %}
package com.zhaoheng.mvc.annotation;

import java.lang.annotation.*;

@Target({ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface RequestParam {
    String value() default "";

    boolean required() default true;
}
{% endhighlight %}

Service

{% highligh ruby %}
package com.zhaoheng.mvc.annotation;
import java.lang.annotation.*;

@Target({ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface Service {
    String value() default "";
}
{% endhighlight %}

#### 3.2 创建基本功能类

添加2个最简单的Service和实现类，模拟查询和修改

ModifyService

{% highligh ruby %}
public interface ModifyService {  
  
    String add(String name, String addr);  
    String remove(Integer id);  
}
{% endhighlight %}

QueryService

{% highligh ruby %}
public interface QueryService {  
    String search(String name);  
}  
{% endhighlight %}

ModifyServiceImpl

{% highligh ruby %}
package com.zhaoheng.mvc.service;

import com.zhaoheng.mvc.annotation.Service;

@Service
public class ModifyServiceImpl implements ModifyService {

    @Override
    public String add(String name, String addr) {
        return "invoke add name = " + name + " addr = " + addr;
    }

    @Override
    public String remove(Integer id) {
        return "remove id = " + id;
    }
}
{% endhighlight %}

QueryServiceImpl

{% highligh ruby %}
package com.zhaoheng.mvc.service;

import com.zhaoheng.mvc.annotation.Service;

@Service("myQueryService")
public class QueryServiceImpl implements QueryService  {
    @Override
    public String search(String name) {
        return "invoke search name = " + name;
    }
} 
{% endhighlight %}

WebController

{% highligh ruby %}
package com.zhaoheng.mvc.controller;

import com.zhaoheng.mvc.annotation.Autowired;
import com.zhaoheng.mvc.annotation.Controller;
import com.zhaoheng.mvc.annotation.RequestMapping;
import com.zhaoheng.mvc.annotation.RequestParam;
import com.zhaoheng.mvc.service.ModifyService;
import com.zhaoheng.mvc.service.QueryService;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@Controller
@RequestMapping("/web")
public class WebController {
    @Autowired("myQueryService")
    private QueryService queryService;
    @Autowired
    private ModifyService modifyService;

    @RequestMapping("/search")
    public void search(@RequestParam("name") String name, HttpServletRequest request, HttpServletResponse response) {
        String result = queryService.search(name);
        out(response, result);
    }

    @RequestMapping("/add")
    public void add(@RequestParam("name") String name,
                    @RequestParam("addr") String addr,
                    HttpServletRequest request, HttpServletResponse response) {
        String result = modifyService.add(name, addr);
        out(response, result);
    }

    @RequestMapping("/update")
    public void update(String name, boolean flag,
                       HttpServletRequest request, HttpServletResponse response) {
        out(response, "我是name：" + name + "flag为：" + flag);
    }

    @RequestMapping("/remove")
    public void remove(@RequestParam("name") Integer id,
                       HttpServletRequest request, HttpServletResponse response) {
        String result = modifyService.remove(id);
        out(response, result);
    }

    private void out(HttpServletResponse response, String str) {
        try {
            response.setContentType("application/json;charset=utf-8");
            response.getWriter().print(str);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
{% endhighlight %}

至此，项目的基本结构就是这样了。下面需要做的就是正文了，`如何让上面的注解生效，如何让请求根据地址进到对应的方法。`

#### 3.3 扫描项目类，并实例化参数

这一步的目的是得到一个类名和类实例的映射对象，如 "webController"->WebController的实例，"searchService"->SearchServiceImpl的实例，
类似于Spring的BeanFactory，将对应的实例赋给对应的beanName。譬如，searchService在Controller中被定义了，它并不需要去做new这个对象的处理，
而是由我们主动注入进去。前提就是我们需要保存一个beanName->bean对象的映射关系。这种处理就是ioc，
也就是早期在spring配置文件application.xml经常配的bean id="XXX" class="XXX"。    
下面来看怎么实例化参数。  
思路就是扫描目录下所有需要被我们的山寨Spring托管的类，并将其实例化，然后保存映射关系。在Spring里就是所有标注了@Component注解的类，
需要被托管。我们这里就只处理@Controller和@Service注解的类，然后实例化。

##### 3.3.1 扫描所有需要被映射的类

修改一下web.xml，指定我们需要扫描的包。

{% highligh ruby %}
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-app_3_1.xsd"
         version="3.1">
    <servlet>
        <servlet-name>dispatchServlet</servlet-name>
        <servlet-class>com.zhaoheng.mvc.DispatcherServlet</servlet-class>
        <init-param>
            <param-name>scanPackage</param-name>
            <param-value>com.zhaoheng.mvc</param-value>
        </init-param>
        <load-on-startup>1</load-on-startup>
    </servlet>
    <servlet-mapping>
        <servlet-name>dispatchServlet</servlet-name>
        <url-pattern>/*</url-pattern>
    </servlet-mapping>
</web-app>
{% endhighlight %}

这里添加了一个init-param，属性名为scanPackage（可任意起名），value为包名。

然后在DispatcherServlet的init方法中，接收并处理。

{% highligh ruby %}
package com.zhaoheng.mvc;  
  
import com.zhaoheng.mvc.annotation.Controller;  
import com.zhaoheng.mvc.annotation.Service;  
  
import javax.servlet.ServletConfig;  
import javax.servlet.ServletException;  
import javax.servlet.http.HttpServlet;  
import javax.servlet.http.HttpServletRequest;  
import javax.servlet.http.HttpServletResponse;  
import java.io.File;  
import java.io.IOException;  
import java.net.URL;  
import java.util.ArrayList;  
import java.util.List; 

public class DispatcherServlet extends HttpServlet {  
    private List<String> classNames = new ArrayList<>();  
  
    @Override  
    public void init(ServletConfig config) throws ServletException {  
        System.out.println("我是初始化方法");  
        scanPackage(config.getInitParameter("scanPackage"));  
        System.out.println(classNames);  
    }  
  
    /** 
     * 扫描包下的所有类 
     */  
    private void scanPackage(String pkgName) {  
        //获取指定的包的实际路径url，将com.zhaoheng.mvc变成目录结构com/zhaoheng/mvc  
        URL url = getClass().getClassLoader().getResource("/" + pkgName.replaceAll("\\.", "/"));  
        //转化成file对象  
        File dir = new File(url.getFile());  
        //递归查询所有的class文件  
        for (File file : dir.listFiles()) {  
            //如果是目录，就递归目录的下一层，如com.zhaoheng.mvc.controller  
            if (file.isDirectory()) {  
                scanPackage(pkgName + "." + file.getName());  
            } else {  
                //如果是class文件，并且是需要被spring托管的  
                if (!file.getName().endsWith(".class")) {  
                    continue;  
                }  
                //举例，className = com.zhaoheng.mvc.controller.WebController  
                String className = pkgName + "." + file.getName().replace(".class", "");  
                //判断是否被Controller或者Service注解了，如果没注解，那么我们就不管它，譬如annotation包和DispatcherServlet类我们就不处理  
                try {  
                    Class<?> clazz = Class.forName(className);  
                    if (clazz.isAnnotationPresent(Controller.class) || clazz.isAnnotationPresent(Service.class)) {  
                        classNames.add(className);  
                    }  
                } catch (ClassNotFoundException e) {  
                    e.printStackTrace();  
                }  
  
            }  
        }  
    }  
  
    @Override  
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {  
        doPost(req, resp);  
    }  
  
    @Override  
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {  
        out(resp, "请求到我啦");  
    }  
  
    private void out(HttpServletResponse response, String str) {  
        try {  
            response.setContentType("application/json;charset=utf-8");  
            response.getWriter().print(str);  
        } catch (IOException e) {  
            e.printStackTrace();  
        }  
    }  
}
{% endhighlight %}

这里定义了一个scanPackage的方法，是用于递归处理web.xml定义的需要被扫描的包下的所有等待被接管的类。我们将所有需要被托管的类，保存到一个list中。供下一步实例化时使用。
写完后，执行看一下被扫描的托管类：
![](http://p4suof94f.bkt.clouddn.com/springmvc_2.jpg)
这样就取到了所有被Controller和Service标注的类了。

##### 3.3.2 实例化bean

我们取到了所有被托管的类，下一步就是要实例化这些类了，也就是像Spring的ioc一样，按规则给bean注入实例值。  
像如果在任何地方定义webController，那么我们就默认给他赋值为WebController的实例，定义了modifyService，
那么就默认给它注入ModifyServiceImpl的实例。倘若用户自定义了beanName，那么就给beanName注入值，如果不定义，
就走上面默认的。如果在ModifyServiceImpl上写了@Service("abc")，那么我们就保存一个"abc"->ModifyServiceImpl的映射，
如果没有定义，就保存一个"modifyService"->ModifyServiceImpl的映射。  
保存映射的目的是在将来给AutoWired注解的属性注入值时，好根据beanName来判断该注入什么实例。  

DispatcherServlet中添加一个map保存beanName和实例的映射。

{% highligh ruby %}
private Map<String, Object> instanceMapping = new HashMap<>(); 
{% endhighlight %} 

添加doInstance

{% highligh ruby %}
@Override  
public void init(ServletConfig config) throws ServletException {  
	System.out.println("我是初始化方法");  
	scanPackage(config.getInitParameter("scanPackage"));  

	doInstance();  

	System.out.println(instanceMapping);  
} 
{% endhighlight %} 

{% highligh ruby %}
/** 
* 实例化 
*/  
private void doInstance() {  
   if (classNames.size() == 0) {  
	   return;  
   }  
   //遍历所有的被托管的类，并且实例化  
   for (String className : classNames) {  
	   try {  
		   Class<?> clazz = Class.forName(className);  
		   //如果是Controller  
		   if (clazz.isAnnotationPresent(Controller.class)) {  
			   //举例：webController -> new WebController  
			   instanceMapping.put(lowerFirstChar(clazz.getSimpleName()), clazz.newInstance());  
		   } else if (clazz.isAnnotationPresent(Service.class)) {  
			   //获取注解上的值  
			   Service service = clazz.getAnnotation(Service.class);  
			   //举例：QueryServiceImpl上的@Service("myQueryService")  
			   String value = service.value();  
			   //如果有值，就以该值为key  
			   if (!"".equals(value.trim())) {  
				   instanceMapping.put(value.trim(), clazz.newInstance());  
			   } else {//没值时就用接口的名字首字母小写  
				   //获取它的接口  
				   Class[] inters = clazz.getInterfaces();  
				   //此处简单处理了，假定ServiceImpl只实现了一个接口  
				   for (Class c : inters) {  
					   //举例 modifyService->new ModifyServiceImpl（）  
					   instanceMapping.put(lowerFirstChar(c.getSimpleName()), clazz.newInstance());  
					   break;  
				   }  
			   }  
		   }  

	   } catch (Exception e) {  
		   e.printStackTrace();  
	   }  
   }  
}  
{% endhighlight %} 

{% highligh ruby %}
private String lowerFirstChar(String className) {  
	char[] chars = className.toCharArray();  
	chars[0] += 32;  
	return String.valueOf(chars);  
} 
{% endhighlight %} 

重新启动执行，来看看映射的结果：
![](http://p4suof94f.bkt.clouddn.com/springmvc_3.jpg)

可以看到，已经按照我们的规则保存好了beanName和实例之间的映射关系了。

下一步就是处理AutoWired了，真正的ioc赋值。

### 4 通过反射给属性和参数注入值

在上一章已经完成了读取beanName->Object映射关系的功能，这一章就是把读取到的映射注入到属性中。

在WebController里定义了需要被Autowired的两个Service，myQueryService和modifyService，下面来给他们赋值。

#### 4.1 通过反射给属性和参数注入值

{% highligh ruby %}
/** 
 * 给被AutoWired注解的属性注入值 
 */  
private void doAutoWired() {  
	if (instanceMapping.isEmpty()) {  
		return;  
	}  
	//遍历所有被托管的对象  
	for (Map.Entry<String, Object> entry : instanceMapping.entrySet()) {  
		//查找所有被Autowired注解的属性  
		// getFields()获得某个类的所有的公共（public）的字段，包括父类;  
		// getDeclaredFields()获得某个类的所有申明的字段，即包括public、private和proteced，但是不包括父类的申明字段。  
		Field[] fields = entry.getValue().getClass().getDeclaredFields();  
		for (Field field : fields) {  
			//没加autowired的不需要注值  
			if (!field.isAnnotationPresent(Autowired.class)) {  
				continue;  
			}  
			String beanName;  
			//获取AutoWired上面写的值，譬如@Autowired("abc")  
			Autowired autowired = field.getAnnotation(Autowired.class);  
			if ("".equals(autowired.value())) {  
				//例 searchService。注意，此处是获取属性的类名的首字母小写，与属性名无关，可以定义@Autowired SearchService abc都可以。  
				beanName = lowerFirstChar(field.getType().getSimpleName());  
			} else {  
				beanName = autowired.value();  
			}  
			//将私有化的属性设为true,不然访问不到  
			field.setAccessible(true);  
			//去映射中找是否存在该beanName对应的实例对象  
			if (instanceMapping.get(beanName) != null) {  
				try {  
					field.set(entry.getValue(), instanceMapping.get(beanName));  
				} catch (IllegalAccessException e) {  
					e.printStackTrace();  
				}  
			}  
		}  
	}  
}  
{% endhighlight %} 

在init方法里，instance下面加上doAutowired方法。

重启，查看注入情况
![](http://p4suof94f.bkt.clouddn.com/springmvc_4.jpg)
可以看到webController里的属性，queryService和modifyService都已经被成功注入了正确的实现类。

#### 4.2 建立Url到方法的映射

当Controller里的属性被注入值后，Service是可以使用了，但是访问Url时，系统依旧不知道该调用哪个方法来处理请求。  
所以当我们请求某个url，如/web/add时，我们需要建立一个Url到Method的映射，这样才能访问到该方法并处理。
这个地方也是SpringMVC区别于Struts2的巨大地方，Struts2是建立url到Controller类的映射，类里的成员变量是所有方法共享的，
无论具体哪个方法都可以访问成员变量，这样会无形中浪费内存空间。而SpringMVC是建立的请求到方法的映射，与成员变量无关。  
那么如何建立Url到方法的映射呢？这里就需要用上@RequestMapping注解了，由它来决定映射。  
  
创建个map

{% highligh ruby %}
private Map<String, Method> handlerMapping = new HashMap<>();  
{% endhighlight %} 

创建方法

{% highligh ruby %}
/** 
 * 建立url到方法的映射 
 */  
private void doHandlerMapping() {  
	if (instanceMapping.isEmpty()) {  
		return;  
	}  
	//遍历托管的对象，寻找Controller  
	for (Map.Entry<String, Object> entry : instanceMapping.entrySet()) {  
		Class<?> clazz = entry.getValue().getClass();  
		//只处理Controller的，只有Controller有RequestMapping  
		if (!clazz.isAnnotationPresent(Controller.class)) {  
			continue;  
		}  

		//定义url  
		String url = "/";  
		//取到Controller上的RequestMapping值  
		if (clazz.isAnnotationPresent(RequestMapping.class)) {  
			RequestMapping requestMapping = clazz.getAnnotation(RequestMapping.class);  
			url += requestMapping.value();  
		}  

		//获取方法上的RequestMapping  
		Method[] methods = clazz.getMethods();  
		//只处理带RequestMapping的方法  
		for (Method method : methods) {  
			if (!method.isAnnotationPresent(RequestMapping.class)) {  
				continue;  
			}  
			RequestMapping methodMapping = method.getAnnotation(RequestMapping.class);  
			//requestMapping.value()即是在requestMapping上注解的请求地址，不管用户写不写"/"，我们都给他补上  
			String realUrl = url + "/" + methodMapping.value();  
			//替换掉多余的"/",因为有的用户在RequestMapping上写"/xxx/xx",有的不写，所以我们处理掉多余的"/"  
			realUrl = realUrl.replaceAll("/+", "/");  
			handlerMapping.put(realUrl, method);  

		}  
	}  
}  
{% endhighlight %} 

通过这个方法就能得到一个HashMap，key为RequestMapping上配置的url地址，value为Method对象。

重启可以看到handlerMapping对象所存储的key-value

理论上来说我们能根据请求的Url，找到对应的需要执行的Method，就已经可以执行method.invoke去调用该方法了。  
在doPost方法中，我们通过遍历HandlerMapping，寻找key等于req.getRequestURI()的Method，然后invoke。  
但是在实际操作中，发现了一个问题，就是method.invoke(Object object, Object... args)方法，它需要两个参数，第一个Object是该
Method所在的类实例，也就是我们的WebController类的实例，目前是存放在instanceMapping中key为webController的值。至于
Object...参数则是该方法的所有参数，也就是@RequestParam("name") String name, HttpServletRequest request, 
HttpServletResponse response这几个。  
但是在我们的上一步操作中，我们的HandlerMapping里只保存了method对象，没有保存Controller对象和所有的参数，所有这一步是执行不下去的。  
那么就需要对HandlerMapping进行改造，把需要的值也放进去。  
新建一个javaBean，来装载Method需要的所有属性
{% highligh ruby %}
package com.zhaoheng.mvc.pojo;

import java.lang.reflect.Method;
import java.util.Map;

public class HandlerModel {
    private Method method;
    private Object controller;
    private Map<String, Integer> paramMap;

    public HandlerModel(Method method, Object controller, Map<String, Integer> paramMap) {
        this.method = method;
        this.controller = controller;
        this.paramMap = paramMap;
    }

    public Method getMethod() {
        return method;
    }

    public void setMethod(Method method) {
        this.method = method;
    }

    public Object getController() {
        return controller;
    }

    public void setController(Object controller) {
        this.controller = controller;
    }

    public Map<String, Integer> getParamMap() {
        return paramMap;
    }

    public void setParamMap(Map<String, Integer> paramMap) {
        this.paramMap = paramMap;
    }
}
{% endhighlight %} 

添加doHandlerMapping方法，来完成Url到方法的映射

{% highligh ruby %}
/**
 * 建立url到方法的映射
 */
private void doHandlerMapping() {
	if (instanceMapping.isEmpty()) {
		return;
	}
	//遍历托管的对象，寻找Controller
	for (Map.Entry<String, Object> entry : instanceMapping.entrySet()) {
		Class<?> clazz = entry.getValue().getClass();
		//只处理Controller的，只有Controller有RequestMapping
		if (!clazz.isAnnotationPresent(Controller.class)) {
			continue;
		}

		//定义url
		String url = "/";
		//取到Controller上的RequestMapping值
		if (clazz.isAnnotationPresent(RequestMapping.class)) {
			RequestMapping requestMapping = clazz.getAnnotation(RequestMapping.class);
			url += requestMapping.value();
		}

		//获取方法上的RequestMapping
		Method[] methods = clazz.getMethods();
		//只处理带RequestMapping的方法
		for (Method method : methods) {
				if (!method.isAnnotationPresent(RequestMapping.class)) {
					continue;
				}
			RequestMapping methodMapping = method.getAnnotation(RequestMapping.class);
			//requestMapping.value()即是在requestMapping上注解的请求地址，不管用户写不写"/"，我们都给他补上
			String realUrl = url + "/" + methodMapping.value();
			//替换掉多余的"/",因为有的用户在RequestMapping上写"/xxx/xx",有的不写，所以我们处理掉多余的"/"
			realUrl = realUrl.replaceAll("/+", "/");
			//获取所有的参数的注解，有几个参数就有几个annotation[]，为毛是数组呢，因为一个参数可以有多个注解……
			Annotation[][] annotations = method.getParameterAnnotations();
			//由于后面的Method的invoke时，需要传入所有参数的值的数组，所以需要保存各参数的位置
			/*以Search方法的这几个参数为例 @RequestParam("name") String name, HttpServletRequest request, HttpServletResponse response
				未来在invoke时，需要传入类似这样的一个数组["abc", request, response]。"abc"即是在Post方法中通过request.getParameter("name")来获取
				Request和response这个简单，在post方法中直接就有。
				所以我们需要保存@RequestParam上的value值，和它的位置。譬如 name->0,只有拿到了这两个值，
				才能将post中通过request.getParameter("name")得到的值放在参数数组的第0个位置。
				同理，也需要保存request的位置1，response的位置2
			 */
			Map<String, Integer> paramMap = new HashMap<>();

			//获取方法里的所有参数的参数名（注意：此处使用了ASM.jar 版本为asm-3.3.1，需要在web-inf下建lib文件夹，引入asm-3.3.1.jar，自行下载）
			//如Controller的add方法，将得到如下数组["name", "addr", "request", "response"]
			String[] paramNames = Play.getMethodParameterNamesByAsm4(clazz, method);

			//获取所有参数的类型，提取Request和Response的索引
			Class<?>[] paramTypes = method.getParameterTypes();

			for (int i = 0; i < annotations.length; i++) {
				//获取每个参数上的所有注解
				Annotation[] anns = annotations[i];
				if (anns.length == 0) {
					//如果没有注解，则是如String abc，Request request这种，没写注解的
					//如果没被RequestParam注解
					// 如果是Request或者Response，就直接用类名作key；如果是普通属性，就用属性名
					Class<?> type = paramTypes[i];
					if (type == HttpServletRequest.class || type == HttpServletResponse.class) {
						paramMap.put(type.getName(), i);
					} else {
						//参数没写@RequestParam注解，只写了String name，那么通过java是无法获取到name这个属性名的
						//通过上面asm获取的paramNames来映射
						paramMap.put(paramNames[i], i);
					}
					continue;
				}

				//有注解，就遍历每个参数上的所有注解
				for (Annotation ans : anns) {
					//找到被RequestParam注解的参数，并取value值
					if (ans.annotationType() == RequestParam.class) {
						//也就是@RequestParam("name")上的"name"
						String paramName = ((RequestParam) ans).value();
						//如果@RequestParam("name")这里面
						if (!"".equals(paramName.trim())) {
							paramMap.put(paramName, i);
						}
					}
				}

			}
			HandlerModel model = new HandlerModel(method, entry.getValue(), paramMap);
			handlerMapping.put(realUrl, model);

		}
	}
}
{% endhighlight %}

还有一个asm取方法名的工具类：

{% highligh ruby %}
package com.zhaoheng.mvc.util;

import org.objectweb.asm.*;

import java.io.InputStream;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;

public class Play {
    /**
     * 获取指定类指定方法的参数名
     *
     * @param method 要获取参数名的方法
     * @return 按参数顺序排列的参数名列表，如果没有参数，则返回null
     */
    public static String[] getMethodParameterNamesByAsm4(final Class clazz, final Method method) {
        final String methodName = method.getName();
        final Class<?>[] methodParameterTypes = method.getParameterTypes();
        final int methodParameterCount = methodParameterTypes.length;
        String className = method.getDeclaringClass().getName();
        final boolean isStatic = Modifier.isStatic(method.getModifiers());
        final String[] methodParametersNames = new String[methodParameterCount];
        int lastDotIndex = className.lastIndexOf(".");
        className = className.substring(lastDotIndex + 1) + ".class";
        InputStream is = clazz.getResourceAsStream(className);
        try {
            ClassReader cr = new ClassReader(is);
            ClassWriter cw = new ClassWriter(ClassWriter.COMPUTE_MAXS);
            cr.accept(new ClassAdapter(cw) {
                @Override
                public MethodVisitor visitMethod(int access, String name, String desc, String signature, String[] exceptions) {

                    MethodVisitor mv = super.visitMethod(access, name, desc, signature, exceptions);

                    final Type[] argTypes = Type.getArgumentTypes(desc);

                    //参数类型不一致
                    if (!methodName.equals(name) || !matchTypes(argTypes, methodParameterTypes)) {
                        return mv;
                    }
                    return new MethodAdapter(mv) {
                        @Override
                        public void visitLocalVariable(String name, String desc, String signature, Label start, Label end, int index) {
                            //如果是静态方法，第一个参数就是方法参数，非静态方法，则第一个参数是 this ,然后才是方法的参数
                            int methodParameterIndex = isStatic ? index : index - 1;
                            if (0 <= methodParameterIndex && methodParameterIndex < methodParameterCount) {
                                methodParametersNames[methodParameterIndex] = name;
                            }
                            super.visitLocalVariable(name, desc, signature, start, end, index);
                        }
                    };
                }
            }, 0);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return methodParametersNames;
    }

    /**
     * 比较参数是否一致
     */
    private static boolean matchTypes(Type[] types, Class<?>[] parameterTypes) {
        if (types.length != parameterTypes.length) {
            return false;
        }
        for (int i = 0; i < types.length; i++) {
            if (!Type.getType(parameterTypes[i]).equals(types[i])) {
                return false;
            }
        }
        return true;
    }
}
{% endhighlight %}

完成这一步后，重启看看映射的结果：
![](http://p4suof94f.bkt.clouddn.com/springmvc_5.jpg)

发现已经正确建立了映射关系。再下一步就可以根据doPost里取到的用户传来的参数找到对应的方法，并invoke方法了。

### 5 匹配用户请求、执行映射方法

在上一章我们已经完成了配置的url到方法的映射，并且完成了method的各参数的注解、参数名、类型等的映射配置。

这一章就很简单了，就是通过获取request的请求地址和参数，和已经加载好的映射进行比对，如果匹配上了就执行对应的方法。

直接上代码：

{% highligh ruby %}
@Override  
protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {  
	//根据请求的URL去查找对应的method  
	try {  
		boolean isMatcher = pattern(req, resp);  
		if (!isMatcher) {  
			out(resp,"404 not found");  
		}  
	} catch (Exception ex) {  
		ByteArrayOutputStream buf = new java.io.ByteArrayOutputStream();  
		ex.printStackTrace(new java.io.PrintWriter(buf, true));  
		String expMessage = buf.toString();  
		buf.close();  
		out(resp, "500 Exception" + "\n" + expMessage);  
	}  
}
{% endhighlight %}	

{% highligh ruby %}
private boolean pattern(HttpServletRequest request, HttpServletResponse response) throws Exception {
	if (handlerMapping.isEmpty()) {
		return false;
	}
	//用户请求地址
	String requestUri = request.getRequestURI();
	String contextPath = request.getContextPath();
	//用户写了多个"///"，只保留一个
	requestUri = requestUri.replace(contextPath, "").replaceAll("/+", "/");

	//遍历HandlerMapping，寻找url匹配的
	for (Map.Entry<String, HandlerModel> entry : handlerMapping.entrySet()) {
		if (entry.getKey().equals(requestUri)) {
			//取出对应的HandlerModel
			HandlerModel handlerModel = entry.getValue();

			Map<String, Integer> paramIndexMap = handlerModel.getParamMap();
			//定义一个数组来保存应该给method的所有参数赋值的数组
			Object[] paramValues = new Object[paramIndexMap.size()];

			Class<?>[] types = handlerModel.getMethod().getParameterTypes();

			//遍历一个方法的所有参数[name->0,addr->1,HttpServletRequest->2]
			for (Map.Entry<String, Integer> param : paramIndexMap.entrySet()) {
				String key = param.getKey();
				if (key.equals(HttpServletRequest.class.getName())) {
					paramValues[param.getValue()] = request;
				} else if (key.equals(HttpServletResponse.class.getName())) {
					paramValues[param.getValue()] = response;
				} else {
					//如果用户传了参数，譬如 name= "wolf"，做一下参数类型转换，将用户传来的值转为方法中参数的类型
					String parameter = request.getParameter(key);
					if (parameter != null) {
						paramValues[param.getValue()] = convert(parameter.trim(), types[param.getValue()]);
					}
				}
			}
			//激活该方法
			handlerModel.getMethod().invoke(handlerModel.getController(), paramValues);
			return true;
		}
	}
	return false;
}
{% endhighlight %}

由于用户传来的都是String，我们需要根据参数的具体类型，进行转换

{% highligh ruby %}
/** 
 * 将用户传来的参数转换为方法需要的参数类型 
 */  
private Object convert(String parameter, Class<?> targetType) {  
	if (targetType == String.class) {  
		return parameter;  
	} else if (targetType == Integer.class || targetType == int.class) {  
		return Integer.valueOf(parameter);  
	} else if (targetType == Long.class || targetType == long.class) {  
		return Long.valueOf(parameter);  
	} else if (targetType == Boolean.class || targetType == boolean.class) {  
		if (parameter.toLowerCase().equals("true") || parameter.equals("1")) {  
			return true;  
		} else if (parameter.toLowerCase().equals("false") || parameter.equals("0")) {  
			return false;  
		}  
		throw new RuntimeException("不支持的参数");  
	}  
	else {  
		//TODO 还有很多其他的类型，char、double之类的依次类推，也可以做List<>, Array, Map之类的转化  
		return null;  
	}  
} 
{% endhighlight %}
以上就OK了。

以下为完整代码
{% highligh ruby %}
package com.zhaoheng.mvc;

import com.zhaoheng.mvc.annotation.*;
import com.zhaoheng.mvc.pojo.HandlerModel;
import com.zhaoheng.mvc.util.Play;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.lang.annotation.Annotation;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DispatcherServlet extends HttpServlet {
    //扫描结果保存
    private List<String> classNames = new ArrayList<>();
    //映射关系
    private Map<String, Object> instanceMapping = new HashMap<>();
    private Map<String, HandlerModel> handlerMapping = new HashMap<>();
    @Override
    public void init(ServletConfig config) throws ServletException {
        System.out.println("我是初始化方法");
        scanPackage(config.getInitParameter("scanPackage"));
        doInstance();
        doAutoWired();
        doHandlerMapping();
        System.out.println("初始化完毕");
    }
    /**
     * 建立url到方法的映射
     */
    private void doHandlerMapping() {
        if (instanceMapping.isEmpty()) {
            return;
        }
        //遍历托管的对象，寻找Controller
        for (Map.Entry<String, Object> entry : instanceMapping.entrySet()) {
            Class<?> clazz = entry.getValue().getClass();
            //只处理Controller的，只有Controller有RequestMapping
            if (!clazz.isAnnotationPresent(Controller.class)) {
                continue;
            }

            //定义url
            String url = "/";
            //取到Controller上的RequestMapping值
            if (clazz.isAnnotationPresent(RequestMapping.class)) {
                RequestMapping requestMapping = clazz.getAnnotation(RequestMapping.class);
                url += requestMapping.value();
            }

            //获取方法上的RequestMapping
            Method[] methods = clazz.getMethods();
            //只处理带RequestMapping的方法
            for (Method method : methods) {
                    if (!method.isAnnotationPresent(RequestMapping.class)) {
                        continue;
                    }
                RequestMapping methodMapping = method.getAnnotation(RequestMapping.class);
                //requestMapping.value()即是在requestMapping上注解的请求地址，不管用户写不写"/"，我们都给他补上
                String realUrl = url + "/" + methodMapping.value();
                //替换掉多余的"/",因为有的用户在RequestMapping上写"/xxx/xx",有的不写，所以我们处理掉多余的"/"
                realUrl = realUrl.replaceAll("/+", "/");
                //获取所有的参数的注解，有几个参数就有几个annotation[]，为毛是数组呢，因为一个参数可以有多个注解……
                Annotation[][] annotations = method.getParameterAnnotations();
                //由于后面的Method的invoke时，需要传入所有参数的值的数组，所以需要保存各参数的位置
                /*以Search方法的这几个参数为例 @RequestParam("name") String name, HttpServletRequest request, HttpServletResponse response
                    未来在invoke时，需要传入类似这样的一个数组["abc", request, response]。"abc"即是在Post方法中通过request.getParameter("name")来获取
                    Request和response这个简单，在post方法中直接就有。
                    所以我们需要保存@RequestParam上的value值，和它的位置。譬如 name->0,只有拿到了这两个值，
                    才能将post中通过request.getParameter("name")得到的值放在参数数组的第0个位置。
                    同理，也需要保存request的位置1，response的位置2
                 */
                Map<String, Integer> paramMap = new HashMap<>();

                //获取方法里的所有参数的参数名（注意：此处使用了ASM.jar 版本为asm-3.3.1，需要在web-inf下建lib文件夹，引入asm-3.3.1.jar，自行下载）
                //如Controller的add方法，将得到如下数组["name", "addr", "request", "response"]
                String[] paramNames = Play.getMethodParameterNamesByAsm4(clazz, method);

                //获取所有参数的类型，提取Request和Response的索引
                Class<?>[] paramTypes = method.getParameterTypes();

                for (int i = 0; i < annotations.length; i++) {
                    //获取每个参数上的所有注解
                    Annotation[] anns = annotations[i];
                    if (anns.length == 0) {
                        //如果没有注解，则是如String abc，Request request这种，没写注解的
                        //如果没被RequestParam注解
                        // 如果是Request或者Response，就直接用类名作key；如果是普通属性，就用属性名
                        Class<?> type = paramTypes[i];
                        if (type == HttpServletRequest.class || type == HttpServletResponse.class) {
                            paramMap.put(type.getName(), i);
                        } else {
                            //参数没写@RequestParam注解，只写了String name，那么通过java是无法获取到name这个属性名的
                            //通过上面asm获取的paramNames来映射
                            paramMap.put(paramNames[i], i);
                        }
                        continue;
                    }

                    //有注解，就遍历每个参数上的所有注解
                    for (Annotation ans : anns) {
                        //找到被RequestParam注解的参数，并取value值
                        if (ans.annotationType() == RequestParam.class) {
                            //也就是@RequestParam("name")上的"name"
                            String paramName = ((RequestParam) ans).value();
                            //如果@RequestParam("name")这里面
                            if (!"".equals(paramName.trim())) {
                                paramMap.put(paramName, i);
                            }
                        }
                    }

                }
                HandlerModel model = new HandlerModel(method, entry.getValue(), paramMap);
                handlerMapping.put(realUrl, model);

            }
        }

    }
    /**
     * 给被AutoWired注解的属性注入值
     */
    private void doAutoWired() {
        if (instanceMapping.isEmpty()) {
            return;
        }
        //遍历所有被托管的对象
        for (Map.Entry<String, Object> entry : instanceMapping.entrySet()) {
            //查找所有被Autowired注解的属性
            // getFields()获得某个类的所有的公共（public）的字段，包括父类;
            // getDeclaredFields()获得某个类的所有申明的字段，即包括public、private和proteced，但是不包括父类的申明字段。
            Field[] fields = entry.getValue().getClass().getDeclaredFields();
            for (Field field : fields) {
                //没加autowired的不需要注值
                if (!field.isAnnotationPresent(Autowired.class)) {
                    continue;
                }
                String beanName;
                //获取AutoWired上面写的值，譬如@Autowired("abc")
                Autowired autowired = field.getAnnotation(Autowired.class);
                if ("".equals(autowired.value())) {
                    //例 searchService。注意，此处是获取属性的类名的首字母小写，与属性名无关，可以定义@Autowired SearchService abc都可以。
                    beanName = lowerFirstChar(field.getType().getSimpleName());
                } else {
                    beanName = autowired.value();
                }
                //将私有化的属性设为true,不然访问不到
                field.setAccessible(true);
                //去映射中找是否存在该beanName对应的实例对象
                if (instanceMapping.get(beanName) != null) {
                    try {
                        field.set(entry.getValue(), instanceMapping.get(beanName));
                    } catch (IllegalAccessException e) {
                        e.printStackTrace();
                    }
                }
            }
        }
    }
    /**
     * 实例化
     */
    private void doInstance() {
        if (classNames.size() == 0) {
            return;
        }
        //遍历所有的被托管的类，并且实例化
        for (String className : classNames) {
            try {
                Class<?> clazz = Class.forName(className);
                //如果是Controller
                if (clazz.isAnnotationPresent(Controller.class)) {
                    //举例：webController -> new WebController
                    instanceMapping.put(lowerFirstChar(clazz.getSimpleName()), clazz.newInstance());
                } else if (clazz.isAnnotationPresent(Service.class)) {
                    //获取注解上的值
                    Service service = clazz.getAnnotation(Service.class);
                    //举例：QueryServiceImpl上的@Service("myQueryService")
                    String value = service.value();
                    //如果有值，就以该值为key
                    if (!"".equals(value.trim())) {
                        instanceMapping.put(value.trim(), clazz.newInstance());
                    } else {//没值时就用接口的名字首字母小写
                        //获取它的接口
                        Class[] inters = clazz.getInterfaces();
                        //此处简单处理了，假定ServiceImpl只实现了一个接口
                        for (Class c : inters) {
                            //举例 modifyService->new ModifyServiceImpl（）
                            instanceMapping.put(lowerFirstChar(c.getSimpleName()), clazz.newInstance());
                            break;
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
    private String lowerFirstChar(String className) {
        char[] chars = className.toCharArray();
        chars[0] += 32;
        return String.valueOf(chars);
    }
    /**
     * 扫描包下的所有类
     */
    private void scanPackage(String pkgName) {
        //获取指定的包的实际路径url，将com.tianyalei.mvc变成目录结构com/tianyalei/mvc
        URL url = getClass().getClassLoader().getResource("/" + pkgName.replaceAll("\\.", "/"));
        //转化成file对象
        File dir = new File(url.getFile());
        //递归查询所有的class文件
        for (File file : dir.listFiles()) {
            //如果是目录，就递归目录的下一层，如com.tianyalei.mvc.controller
            if (file.isDirectory()) {
                scanPackage(pkgName + "." + file.getName());
            } else {
                //如果是class文件，并且是需要被spring托管的
                if (!file.getName().endsWith(".class")) {
                    continue;
                }
                //举例，className = com.tianyalei.mvc.controller.WebController
                String className = pkgName + "." + file.getName().replace(".class", "");
                //判断是否被Controller或者Service注解了，如果没注解，那么我们就不管它，譬如annotation包和DispatcherServlet类我们就不处理
                try {
                    Class<?> clazz = Class.forName(className);
                    if (clazz.isAnnotationPresent(Controller.class) || clazz.isAnnotationPresent(Service.class)) {
                        classNames.add(className);
                    }
                } catch (ClassNotFoundException e) {
                    e.printStackTrace();
                }

            }
        }
    }
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        doPost(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        //根据请求的URL去查找对应的method
        try {
            boolean isMatcher = pattern(req, resp);
            if (!isMatcher) {
                out(resp,"404 not found");
            }
        } catch (Exception ex) {
            ByteArrayOutputStream buf = new java.io.ByteArrayOutputStream();
            ex.printStackTrace(new java.io.PrintWriter(buf, true));
            String expMessage = buf.toString();
            buf.close();
            out(resp, "500 Exception" + "\n" + expMessage);
        }
    }

    private void out(HttpServletResponse response, String str) {
        try {
            response.setContentType("application/json;charset=utf-8");
            response.getWriter().print(str);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    private boolean pattern(HttpServletRequest request, HttpServletResponse response) throws Exception {
        if (handlerMapping.isEmpty()) {
            return false;
        }
        //用户请求地址
        String requestUri = request.getRequestURI();
        String contextPath = request.getContextPath();
        //用户写了多个"///"，只保留一个
        requestUri = requestUri.replace(contextPath, "").replaceAll("/+", "/");

        //遍历HandlerMapping，寻找url匹配的
        for (Map.Entry<String, HandlerModel> entry : handlerMapping.entrySet()) {
            if (entry.getKey().equals(requestUri)) {
                //取出对应的HandlerModel
                HandlerModel handlerModel = entry.getValue();

                Map<String, Integer> paramIndexMap = handlerModel.getParamMap();
                //定义一个数组来保存应该给method的所有参数赋值的数组
                Object[] paramValues = new Object[paramIndexMap.size()];

                Class<?>[] types = handlerModel.getMethod().getParameterTypes();

                //遍历一个方法的所有参数[name->0,addr->1,HttpServletRequest->2]
                for (Map.Entry<String, Integer> param : paramIndexMap.entrySet()) {
                    String key = param.getKey();
                    if (key.equals(HttpServletRequest.class.getName())) {
                        paramValues[param.getValue()] = request;
                    } else if (key.equals(HttpServletResponse.class.getName())) {
                        paramValues[param.getValue()] = response;
                    } else {
                        //如果用户传了参数，譬如 name= "wolf"，做一下参数类型转换，将用户传来的值转为方法中参数的类型
                        String parameter = request.getParameter(key);
                        if (parameter != null) {
                            paramValues[param.getValue()] = convert(parameter.trim(), types[param.getValue()]);
                        }
                    }
                }
                //激活该方法
                handlerModel.getMethod().invoke(handlerModel.getController(), paramValues);
                return true;
            }
        }
        return false;
    }
    /**
     * 将用户传来的参数转换为方法需要的参数类型
     */
    private Object convert(String parameter, Class<?> targetType) {
        if (targetType == String.class) {
            return parameter;
        } else if (targetType == Integer.class || targetType == int.class) {
            return Integer.valueOf(parameter);
        } else if (targetType == Long.class || targetType == long.class) {
            return Long.valueOf(parameter);
        } else if (targetType == Boolean.class || targetType == boolean.class) {
            if (parameter.toLowerCase().equals("true") || parameter.equals("1")) {
                return true;
            } else if (parameter.toLowerCase().equals("false") || parameter.equals("0")) {
                return false;
            }
            throw new RuntimeException("不支持的参数");
        }
        else {
            //TODO 还有很多其他的类型，char、double之类的依次类推，也可以做List<>, Array, Map之类的转化
            return null;
        }
    }
}
{% endhighlight %}

重启Tomcat，测试一下。
![](http://p4suof94f.bkt.clouddn.com/springmvc_6.jpg)

把里面的方法都试一下，发现基本已经OK了，只要参数传对，整个流程是能走通的。

还有一些遗留问题，譬如flag不传值时，注入时默认为null，而方法中定义的是boolean，所以会报错。这里就牵扯到一个require的问题了，
就是说该参数是否是必传的，还有是否需要我们赋默认值的问题。

当然了，扩展起来还是很简单的，譬如SpringMVC在遇到小写的boolean或者int时，而用户又不传值时会赋默认值，做法应该就是遍历参数值数组，将为null的赋初值。
如果是大写的Boolean就不赋值。如果在RequestParam上加了require为true，那么当为null时，我们应该直接抛出异常给用户。

还有一些比较难点的扩展，譬如/web/query/{userId},@PathVariable, @ModelAttribute，还有正则匹配/web/*，ModelMap，ModelAndView还有参数校验Hibernate Valider等等，
SpringMVC非常强大，但是原理基本就是这样。在这个基础上，我们也是可以完成上面那些扩展的。
