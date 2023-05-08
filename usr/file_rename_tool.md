# fl

fl: file loop. rename / add ext / rm ext / etc
works on all files (or files matching pattern) in a directory

- does not remove any files
- all files are backed up before being renamed
- current dir is assumed if no directory is passed



```

# help

fl
fl -h
fl --help

# commands

fl name ext add "txt" dir
fl pattern ext add "txt" dir

fl name ext rm "txt" dir
fl pattern ext rm "txt" dir

fl dupe dir
fl dupe "pattern" dir

fl touch dir 
fl touch "pattern" dir

fl copy dir
fl copy "pattern" dir

fl move dir
fl move "pattern" dir

```
