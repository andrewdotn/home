import os
import time
from checkstamp import mangle
from contextlib import contextmanager

# slightly modified from original written 2008-03-30
@contextmanager
def temp_tz(tz):
    "Temporarily set the timezone, and restore afterwards"

    save_tz = os.environ.get('TZ', None)
    os.environ['TZ'] = tz
    time.tzset()

    try:
        yield
    finally:
        if type(save_tz) == type(None):
            del os.environ['TZ']
        else:
            os.environ.set('TZ', save_tz)
        time.tzset()

def test_basics():
    with temp_tz('America/New_York'):
        assert (str(mangle('foo.bar.baz', timestamp=1607875239.70066))
            == 'foo.bar~20201213_1100-0500.baz')

        assert (str(mangle('foo', timestamp=1607875239.70066))
            == 'foo~20201213_1100-0500')

        assert (str(mangle('foo.bar', timestamp=1607875239.70066))
            == 'foo~20201213_1100-0500.bar')

    with temp_tz('America/Edmonton'):
        assert (str(mangle('foo.bar.baz', timestamp=1607884429))
            == 'foo.bar~20201213_1133-0700.baz')

    with temp_tz('America/Edmonton'):
        assert (str(mangle('foo.bar.baz', timestamp=1590991200))
            == 'foo.bar~20200601_0000-0600.baz')

    with temp_tz('Europe/Berlin'):
        assert (str(mangle('foo.bar.baz', timestamp=1607884429))
            == 'foo.bar~20201213_1933+0100.baz')

    # 15-minute offset
    with temp_tz('Pacific/Chatham'):
        assert (str(mangle('foo.bar.baz', timestamp=1607886312))
            == 'foo.bar~20201214_0850+1345.baz')
