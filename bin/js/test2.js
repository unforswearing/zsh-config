import * as std from 'std'
import * as os from 'os'
// using QuickJS
let testpath = [
  "",
  "Users",
  "unforswearing",
  "zsh-config",
  "bin",
  "js",
  "test.js"
]

let jsfile = std.loadFile(testpath.join("/"))

os.sleep(2000)

console.log(`Contents of ${testpath.join("/")}`)
console.log("---------------------------------")
console.log(jsfile)
