#!/bin/sh

':' //; exec "$(command -v nodejs || command -v node)" "$0" "$@"

// run nodejs scripts through posix sh
// see: https://unix.stackexchange.com/a/65295

console.log('Hello world!');
console.log(process.argv[2])
