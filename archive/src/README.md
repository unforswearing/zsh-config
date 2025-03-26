# Using `/src` and `/src/bin`

Tools in the src folder are acessible in lua scripts when using the `luash` module: <https://github.com/zserge/luash>.

```lua
require("sh")
add(2, 2)
memory()
color("green", "done!")
```

## function generate_binfiles

use the `generate_binfiles` function to create a runner file for lua scripts from a shell function. *binfiles* are stored in `/src/bin`. 

**note:** `luash` makes lua functions from top-level zsh commands, like `cat` and `ls`. not all zsh commands are compatible with `luash`. likewise, not all functions created with `generate_binfile` will work in `lua` with `luash`. 

but anyway

## create a binfile

create a *binfile* in `zsh`

```zsh
function helloworld() {
  print "hello world"
}

generate_binfile "helloworld"
```

create a *binfile* in `lua`

```lua
require("sh")
-- assuming the `helloworld` function has been created
generate_binfile("helloworld")
helloworld()
```
