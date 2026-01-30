# Detect the start of any multiline blocks
/^[[:space:]]*.*:[[:space:]]*\|/ {
    in_block = 1
    first_line = 1
    print
    next
}

# Leave the block when we meet the next top‑level key (word chars then :) or a blank line
in_block && (/^[[:space:]]*[A-Za-z0-9_-]+:[[:space:]]/ || /^[[:space:]]*$/) {
    in_block = 0
    first_line = 0
}

# While inside the block, add two spaces in front of every line except the first
{
    if (in_block && first_line) {
        first_line = 0
        print $0
    } else {
        print (in_block ? "  " : "") $0
    }
}
