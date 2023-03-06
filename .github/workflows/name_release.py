from datetime import datetime
from string import ascii_lowercase as abc
import os

t = datetime.now()
base = t.strftime('%gw%V')

for letter in abc:
    tag = base + letter

    if os.system('git show-ref --quiet --tags ' + tag) != 0:
        os.system(f'echo release_name={tag} >> $GITHUB_OUTPUT')
        break
else:
    raise hell
