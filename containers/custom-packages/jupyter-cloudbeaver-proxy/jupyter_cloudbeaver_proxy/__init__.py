import os
import tempfile
import getpass
from textwrap import dedent

def setup_cloudbeaver():
    '''Manage a Cloudbeaver instance.'''

    return {
        'command': ['/bin/bash', '-c', 'cd /opt/cloudbeaver && ./run-server.sh', '{port}'],
        'port': 8978,
        'timeout': 60,
        'absolute_url': True,
        'new_browser_tab': False,
        'launcher_entry': {
            'title': 'CloudBeaver',
            'icon_path': os.path.join(os.path.dirname(os.path.abspath(__file__)), 'icons', 'cloudbeaver.svg')
        },
        "request_headers_override": {
            "X-User": "cbadmin",
            "X-Role": "user|admin"
        }
    }