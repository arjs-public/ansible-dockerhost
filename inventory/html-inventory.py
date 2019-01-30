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

    # print url
    response = urlopen(url)
    # print response
    data = str(response.read())
    # print data
    # print json.loads(data)
    return json.loads(data)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group()
    group.required = True
    group.add_argument("--list", action="store_true")
    group.add_argument("--host", nargs=1)
    args = parser.parse_args()
    # print args

    data = {
        '_meta': {
            'hostvars': {
            }
        },
        'all':
        {
            'children': [
                'ungrouped'
            ]
        },
        'ungrouped': {
            'hosts': [                    
            ]
        }
    }
    if args.host:
        jsond = get_json_data('http://ansible.cmdb.info:8098/hosts/?value=' + str(args.host))
        args.list = True if not args.host and not args.group else False
    else:
        jsond = get_json_data('http://ansible.cmdb.info:8098/hosts/')
        # print jsond

        for _host in jsond:
            _host_name = str(_host['host'])
            data['ungrouped']['hosts'].append(_host_name)
            data['_meta']['hostvars'][_host_name] = {}
            for _vars in _host['vars']:
                data['_meta']['hostvars'][_host_name][str(_vars)] = str(_host['vars'][_vars])

        jsond = get_json_data('http://ansible.cmdb.info:8098/groups/')
        # print jsond

        for _group in jsond:
            _group_name = str(_group['name'])
            if ':children' in _group_name:
                _group_name = _group_name.replace(':children', '')
                data[_group_name] = {
                    'children': []
                }
                for _value in _group['value']:
                    data[_group_name]['children'].append(str(_value))
            else:
                data[_group_name] = {
                    'hosts': []
                }
                for _value in _group['value']:
                    _host = str(_value)
                    data[_group_name]['hosts'].append(_host)
                    if _host in data['ungrouped']['hosts']:
                        data['ungrouped']['hosts'].remove(_host)

            data['all']['children'].append(_group_name)

    print data
