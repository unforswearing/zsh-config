function dir.rmempty() { find $(pwd) -type d -empty -print -delete; }
function file.rmempty() { find $(pwd) -type f -empty -print -delete; }
function rmempty() { file rmempty && dir rmempty; }
function rm.dsstore() { find $(pwd) -name '*.DS_Store' -type f -ls -delete; }
