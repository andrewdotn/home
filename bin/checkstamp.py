"""
Checkstamp: Create timestamped checkpoints of files

For example, ‘foo.bar’ may be copied to ‘foo~20201213_1133-0700.bar’.

The modification time of the file is used, not the current time.

‘~’ is chosen as the delimiter because it sorts late in ASCII, preventing
backup files from showing up before the real file.
"""

import hashlib
import math
import os
import shutil
import sys
import time
from argparse import ArgumentParser
from datetime import datetime, tzinfo
from pathlib import Path

def hash_path_contents(path):
    h = hashlib.sha256()

    with path.open('rb') as f:
        while True:
            data = f.read(1 << 20)
            if len(data) > 0:
                h.update(data)
            else:
                break
        return h.hexdigest()

def timetuple_with_dst(t, tm_isdst):
    return time.struct_time((t.tm_year, t.tm_mon, t.tm_mday,  t.tm_hour,
                             t.tm_min, t.tm_sec, t.tm_wday, t.tm_yday,
                             tm_isdst))

def format_time(timestamp=None):
    "Turn an epoch timestamp into YYYYMMDD_HHMM±ZZZZ, using system TZ"
    if timestamp is None:
        timestamp = time.time()

    # the tzlocal package would work here, but requires an extra dependency
    # to be installed, and due to caching you have to remember to call
    # reload_localzone()

    localtime = time.localtime(timestamp)
    yyyymmdd_hhmm = time.strftime("%Y%m%d_%H%M", localtime)

    gmtoff = localtime.tm_gmtoff
    sign = "+" if gmtoff >= 0 else "-"

    gmtoff = abs(gmtoff)
    offset_hours = math.floor(gmtoff / 3600)
    offset_minutes = (gmtoff / 60) % 60

    return f'{yyyymmdd_hhmm}{sign}{offset_hours:02.0f}{offset_minutes:02.0f}'

def mangle(filename, timestamp=None):
    """
    Create a timestamped backup-filename for filename

    How to distinguish between foo.bar.html → foo.bar~123.html, and
    foo.tar.gz → foo~123.tar.gz? No universal answer, heuristics or a
    simple default are the best we can do. We choose a simple default.
    """

    path = Path(filename)
    suffix = path.suffixes[-1] if len(path.suffixes) > 0 else ""
    name = path.name.removesuffix(suffix)

    new_name = name + '~' + format_time(timestamp) + suffix

    return path.with_name(new_name)

def checkstamp_file(path):
    """
    Copy path to its backup location. Returns None, unless there is an
    error, in which case an error description string is returned.
    """

    path = Path(path)

    stat = path.stat()
    new_path = mangle(path, timestamp=stat.st_mtime)

    if os.path.exists(new_path):
        if hash_path_contents(path) == hash_path_contents(new_path):
            print(f'{new_path} is already a copy')
        else:
            return f'{new_path} already exists and has different contents'
    else:
        shutil.copy(path, new_path)
        os.utime(new_path, (stat.st_atime, stat.st_mtime))
        print(f'Copied to {new_path}')

if __name__ == '__main__':
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('file', nargs="+")
    args = parser.parse_args()

    error_count = 0
    for path in args.file:
        error_msg = checkstamp_file(path)
        # We keep going on error, because we were asked to back up some
        # files, so let’s back up as many of them as possible even if we
        # encounter an error.
        if error_msg is not None:
            print(f'Error: {error_msg}', file=sys.stderr)
            error_count += 1
    if error_count != 0:
        print(f'{error_count} error(s) encountered', file=sys.stderr)
        sys.exit(1)
