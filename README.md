# LuaWorld
It's yet another analyzer but with no features and written in lua

## Installation
Note that this analyzer has not been tested on windows. It may work, it may not.

### Compiler
LuaWorld uses Lua 5.1. I'd recommend using the [JIT compiler](http://luajit.org/install.html) for Lua, but you can also use the official [lua compiler](https://lua.org/download.html).

### Luarocks
You'll need to install the following packages using [luarocks](https://github.com/luarocks/luarocks):
- [lua-utf8](https://github.com/starwing/luautf8)
- [luafilesystem](https://github.com/lunarmodules/luafilesystem)

Ensure that these packages are compiled using the correct version. Run `$ luarocks`, and you should see the version for lua is set to 5.1.

## Running
For the JIT compiler, run `$ luajit main.lua`. For the standard compiler, run `$ lua main.lua`. From there, type `help` to get a list of available commands.
