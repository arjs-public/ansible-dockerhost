#!/usr/bin/env python

try:
    # For Python 3.0 and later
    from urllib.request import urlopen
except ImportError:
    # Fall back to Python 2's urllib2
    from urllib2 import urlopen

import os
import json
import argparse


def get_json_data(url):
    """Receive the content of ``url``, parse it as JSON and return the
       object.
    """

    response = urlopen(url)
    data = str(response.read())
    return json.loads(data)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--host")
    parser.add_argument("--group")
    parser.add_argument("--env")
    args = parser.parse_args()
    # print args
    if args.env:
        jsond = get_json_data('http://ansible.cmdb.info/hosts/' + str(args.env))
        args.list = True if not args.host and not args.group else False
    else:
        jsond = get_json_data('http://ansible.cmdb.info/hosts/' + str(os.path.basename(__file__)).replace('inv-', ''))

    hosts = []
    for k,v in jsond.items():
        print k,v
        if type(v) is list:
            for h in v:
                if h not in hosts:
                    hosts.append(h)
        elif type(v) is dict:
            if 'hosts' in v:
                for h in v['hosts']:
                    if h not in hosts:
                        hosts.append(h)

    # print hosts
    if args.list:
        print json.dumps(jsond, indent=4)
    elif args.host:
        if args.host and args.host in hosts:
            print '{{"hostname": "{}" }}'.format(args.host)
        else:
            print "{}"
    elif args.group:
        print '{{"{}": {} }}'.format(args.group, json.dumps(jsond[args.group], indent=4))
    else:
        print "{}"
