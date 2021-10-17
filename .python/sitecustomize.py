import locale
import sys
import platform

if platform.python_version() == '3.9.0+':
    # This is the default version claimed by Ubuntu python3.9. But it is an
    # invalid version number according to PEP 440, so it gets treated as a
    # string in version comparison when doing something like `pip install
    # "nbclient==0.5.3; python_full_version >= '3.6.1'"`, which is what
    # pipenv is doing behind the scenes, leading to errors on `pipenv
    # install` like `Ignoring nbclient: markers 'python_full_version >=
    # "3.6.1"' don't match your environment`.
    platform.python_version = lambda: '3.9.0'
    platform.python_version_tuple = lambda: ('3', '9', '0')

if hasattr(sys, 'setdefaultencoding'):
    sys.setdefaultencoding(locale.getpreferredencoding().lower())
