# docker build

## 依赖说明

**zlib zlib-devel**: 用于安装ruby后使用gem命令出现的下面错误
```bash
# gem install -l redis-3.3.0.gem
ERROR:  Loading command: install (LoadError)
cannot load such file -- zlib
ERROR:  While executing gem ... (NoMethodError)
undefined method `invoke_with_build_args' for nil:NilClass
```