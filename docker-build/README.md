# docker build

## 场景说明

el7.altarch、el8.aarch64 用于 MacOS arm64，其余则用于 x86_64 架构。

## 依赖说明

**zlib zlib-devel**: 用于安装ruby后使用gem命令出现的下面错误
```bash
# gem install -l redis-3.3.0.gem
ERROR:  Loading command: install (LoadError)
cannot load such file -- zlib
ERROR:  While executing gem ... (NoMethodError)
undefined method `invoke_with_build_args' for nil:NilClass
```