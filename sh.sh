#!/usr/bin/env bash
s=$'#!/usr/bin/env bash\ns=%q\nprintf "$s" "$s"\n'
printf "$s" "$s"
