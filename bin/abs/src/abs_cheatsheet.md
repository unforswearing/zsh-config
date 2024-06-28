# Abs Cheatsheet

[Abs](https://www.abs-lang.org/)

[Builtin Functions](https://www.abs-lang.org/types/builtin-function/)
[Decorators](https://www.abs-lang.org/types/decorator/)

```python
"hello world"[1] # e

"string"[-2] # "n"
"string"[0:3] # "str"
"string"[:3] # "str"
"string"[1:] # "tring"
"hello" + " " + "world" # "hello world"

!!"" # false

"string".any("abs") # true
"string".any("xyz") # false

"string string".last_index("g") # 13
"string string".last_index("ri") # 9

"hello world".len() # 11

"first\nsecond".lines() # ["first", "second"]

"STRING".lower() # "string"
"string".upper() # "STRING"
"a short sentence".snake() # a_short_sentence
"a short sentence".camel() # aShortSentence
"a short sentence".kebab() # a-short-sentence
"hello world".title() # "Hello World"

"1.2.3.4".split(".") # ["1", "2", "3", "4"]
"1 2 3 4".split()    # ["1", "2", "3", "4"]

"string".suffix("ing") # true
"string".suffix("ong") # false

"string".str() # "string"

" string     ".trim() # "string"
"string".trim_by("g") # "strin"
"stringest".trim_by("st") # "ringe"

"99.5".number() # 99.5
"a".number() # ERROR: int(...) can only be called on strings which represent numbers, 'a' given
#

"string".prefix("str") # true
"string".prefix("abc") # false
#
"hello world".reverse() # "dlrow olleh"

"string".repeat(2) # "stringstring"

"string".replace("i", "o", -1) # "strong"
"aaaa".replace("a", "x") # "xxxx"
"aaaa".replace("a", "x", 2) # "xxaa"
"A man, a plan, a canal, Panama!".replace("a ", "ur-") # "A man, ur-plan, ur-canal, Panama!"

"str" in "string"   # true
"xyz" in "string"   # false

"hello %s".fmt("world") # "hello world"

"string".index("t") # 1
"string".index("ri") # 2
#

"99.5".int() # 99
"-99.5".int() # -99
"a".int() # ERROR: int(...) can only be called on strings which represent numbers, 'a' given

"99.5".is_number() # true
"a".is_number() # false

s = '{"a": 1, "b": "string", "c": true, "d": {"x": 10, "y": 20}}'
h = s.json()
h # {a: 1, b: string, c: true, d: {x: 10, y: 20}}

if x > 0 {
    echo("x is high")
} else if x < 0 {
    echo("x is low")
} else {
    echo("x is actually zero!")
}

for x = 0; x < 10; x = x + 1 {
    echo("Looping...")
}

x = "hello world"

for x = 0; x < 10; x = x + 1 {
    # x is 0, 1, 2...
}

echo(x) # "hello world"

for x in [1, 2, 3] {
    # x is 1, 2, 3
}

for x in {"a": 1, "b": 2, "c": 3} {
    # x is 1, 2, 3
}

for k, v in [1, 2, 3] {
    # k is 0, 1, 2
    # v is 1, 2, 3
}

for k, v in {"a": 1, "b": 2, "c": 3} {
    # k is a, b, c
    # v is 1, 2, 3
}

users = db.query("SELECT students WHERE age > 20")

for user in users {
  print(user)
} else {
  print("We don't have students above the age of 20")
}

x = 0

while x < 100 {
    x = x + 1
}

echo(x) # 99

date = `date` # "Sun Apr 1 04:30:59 +01 1995"

if `ls -la`.ok {
    echo("hello world")
}

cmd = `sleep 10 &`
cmd.done # false
`sleep 11`
cmd.done # true

cmd = `sleep 10 &`
echo("This will be printed right away!")
cmd.wait()
echo("This will be printed after 10s")

cmd = `sleep 10 &`
cmd.done # false
cmd.kill()
cmd.done # true

file = "cpuinfo"
x = `cat /proc/$file`

cmd = args(2)
filename = args(3)
exec("sudo $cmd $filename")

`echo \$0` # bash
env("ABS_COMMAND_EXECUTOR", "sh -c")
`echo \$0` # sh

[1, 2, 3].chunk(2) # [[1, 2], [3]]
[1, 2, 3].diff([3, 1]) # [2]
[1, 2, 3].diff_symmetric([3, 1]) # [2]
[0, 1, 2].every(f(x){type(x) == "NUMBER"}) # true
["hello", 0, 1, 2].filter(f(x){type(x) == "NUMBER"}) # [0, 1, 2]
["hello", 0, 1, 2].find(f(x){type(x) == "NUMBER"}) # 0
[[1, 2, 3, 4]].flatten() # [1, 2, 3, 4]
[[[1, 2], [3, 4], 5, 6], 7, 8].flatten() # [[1, 2], [3, 4], 5, 6, 7, 8]
[[[1, 2], [[[[3]]]], [4]]].flatten_deep() # [1, 2, 3, 4]
[1, 2, 3].intersect([3, 1]) # [1, 3]
[1, 2, 3].join("_") # "1_2_3"
(1..2).keys() # [0, 1]
[1, 2].len() # 2
[0, 1, 2].map(f(x){x+1}) # [1, 2, 3]
[0, 5, -10, 100].max() # 100
[0, 5, -10, 100].min() # -10
a = [1, 2, 3]
a.pop() # 3
a # [1, 2]
[1, 2].push(3) # [1, 2, 3]
[1, 2, 3, 4].reduce(f(value, element) { return value + element }, 10) # 20
[1, 2].reverse() # [2, 1]
a = [1, 2, 3]
a.shift() # 1
a # [2, 3]
#
a = [1, 2, 3, 4]
a.shuffle() # [3, 1, 2, 4]
[0, 1, 2].some(f(x){x == 1}) # true
[0, 1, 2].some(f(x){x == 4}) # false
[3, 1, 2].sort() # [1, 2, 3]
["b", "a", "c"].sort() # ["a", "b", "c"]
[1, 2].str() # "[1, 2]"
[1, 1, 1].sum() # 3
[["LeBron", "James"], ["James", "Harden"]].tsv()
[1, 2, 3].union([3]) # [1, 2, 3]
[2, 1, 2, 3].unique() # [2, 1, 3]


```