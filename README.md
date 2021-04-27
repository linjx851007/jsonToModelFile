闲下来整理下自己这段时间添加的需求，在原有版本基础上增加：

1.修复我最早clone下来的版本多属性跟多字典时会写入错误的问题，并替换id跟new属性（早期的Xcode不会对这2个关键词报错）。

2.视情况选择是否import头文件，因为我是所有Model放一个文件里的，所以除了项目创建完第一次需要，后续不希望每次都有import然后拷贝过去再删除声明。

3.增加基类属性的支持。

因为服务端下发的json有一些基础属性，如success或者code，这些属性一开始就创建了一个基类以替代NSObject，所以后续生成的model希望是继承基类。



#JsonToModelFile
    在开发的过程中，服务器会给客户端返回Json类型的数据。为了方便操作，经常需要把Json类型的数据转化成实体，这就需要我们来建立各种实体。

​	JsonToModelFile这个mac端的应用，可以帮我们把json转化过程中所需要的文件都自动化的生成。把Json数据转化成类文件，与MJExtension或者YYModel配套使用。



基础版本是很早以前下载的JsToClassFile，后来自己一直在这个基础上根据工作需要做优化，感谢https://github.com/lqCoder/JsToClassFile。
