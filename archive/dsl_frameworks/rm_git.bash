git filter-branch --force --index-filter "git rm --cached --ignore-unmatch reload.txt" --prune-empty --tag-name-filter cat -- --all
