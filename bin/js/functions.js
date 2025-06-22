import * as std from 'std'
import * as os from 'os'

let funcs = JSON.parse(std.loadFile('././functions.json')).functions
// console.log(Object.keys(funcs))
console.log(os.readdir(os.getcwd()[0]))
