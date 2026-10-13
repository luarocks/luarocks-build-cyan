# luarocks-build-cyan

A [LuaRocks](https://luarocks.org) build backend for installing modules
written in the [Teal](https://teal-language.org) language and 
built using the [Cyan](https://github.com/teal-language/cyan) build tool.

# Using

Configure your Cyan project as normal, adding a `tlconfig.lua` file to the
root of your repository, then add the following entries to your rockspec:

```lua
rockspec_format = "3.0" -- to enable build_dependencies

build_dependencies = {
   "luarocks-build-cyan" -- to enable build.type = "cyan"
}

build = {
   type = "cyan"
}
```
