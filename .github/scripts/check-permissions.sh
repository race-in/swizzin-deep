#!/bin/bash
exit_code=0

check_permission() {
    expected=$1
    file=$2

    permissions=$(stat -L -c "%a" "$file")
    if [ "$permissions" != "$expected" ]; then
        echo "'$file' has incorrect permissions '$permissions', should be '$expected'"
        return 1
    fi
}

# Check so that all scripts has --rwxr-xr-x = 755
while IFS= read -r file; do
    check_permission 755 "$file" || exit_code=1
done < <(find scripts)

# Check so that all sources has --rw-r--r-- = 644
while IFS= read -r file; do
    check_permission 644 "$file" || exit_code=1
done < <(find sources -type f)

# Check so that all directories in sources has --rwxr-xr-x = 755
while IFS= read -r folder; do
    check_permission 755 "$folder" || exit_code=1
done < <(find sources -type d)

exit "$exit_code"
