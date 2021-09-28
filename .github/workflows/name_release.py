from datetime import datetime
from string import ascii_lowercase as abc

t = datetime.now()
base = t.strftime('%gw%V')

for letter in abc:
    tag = base + letter

    if os.system('git show-ref --quiet --tags ' + tag) != 0:
        print('::set-output name=release_name::' + tag)
        break
else:
    raise hell
