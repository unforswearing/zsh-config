# Log 

## Changes, 5/21/2023

The original zshrc broke things so I backed out. Changes include

- not currently using ZDOTDIR
- using zshrc, zshenv, and zshconfig from $HOME
- sourcing items in zsh-config/bin from within zshrc
- teal will not be used
- there is still a possiblility for rewriting files in /zsh-config/usr in lua
- lua will be used for scripts using the following as a shell library
  - luash
  - stdlib.zsh
  - zsh-config/src/bin 
  - generate_binfile 
- all lua scripts will start with

```lua
require("sh")
color("red", "colors work")
```

## Changes, 5/7/2023

Much of the zsh.dsl functionality will be replaced with lua / [teal](https://github.com/teal-language/tl) [types](https://pdesaulniers.github.io/tl/tutorial), [luash](https://github.com/zserge/luash), [ansicolors](https://github.com/kikito/ansicolors.lua), and [luafilesystem](https://github.com/lunarmodules/luafilesystem).

The idea is to bring different 'plumbing' and types to zsh with a new language, however writing a new language isn't necessary. See ~cloud/Notes/language.sl for the original specification.

All `teal` scripts should include the following header:

```lua
colors = require("ansicolors")
require("luafilesystem")
require("sh")
```

Anything that is not interactive can be rewritten in teal. Focus on rewriting the following source files from `/bin`

- conv.zsh
- dsl.zsh
- fs.zsh 
  - files()
  - dir()
- utils.zsh
  - sys()
  - zc()
  - external()
  - update()...
- zdb.zsh (maybe)

Resources

- <https://learnxinyminutes.com/docs/lua/>
- <https://www.lua.org/pil/>
- <http://lua-users.org/wiki/>
  - <http://lua-users.org/wiki/StringLibraryTutorial>
  - <http://lua-users.org/wiki/TableLibraryTutorial>
  - <http://lua-users.org/wiki/IoLibraryTutorial>
  - <http://lua-users.org/wiki/OsLibraryTutorial>
- <https://github.com/teal-language/tl>
- <https://pdesaulniers.github.io/tl/tutorial.html>
- <https://github.com/zserge/luash>
- <https://github.com/lunarmodules/luafilesystem>

---