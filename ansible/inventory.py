#!/usr/bin/env python3
import json
import yaml
import sys
import os
import argparse

def get_inventory():
    config_path = os.path.join(os.path.dirname(__file__), '..', 'config', 'network.yaml')

    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)

    hosts = config['networks']['main']['hosts']

    inventory = {
        'proxmox_hosts': {
            'hosts': ['homeserver']
        },
        'k3s_cluster': {
            'hosts': ['k3s-cluster']
        },
        'circleci_runner': {
            'hosts': ['circleci-runner']
        },
        'raspberry_pis': {
            'hosts': ['services-pi']
        },
        'example_tailscale': {
            'hosts': ['example-tailscale']
        },
        'tailscale_exit_node': {
            'hosts': ['tailscale-exit-node']
        },
        'openclaw': {
            'hosts': ['openclaw']
        },
        'promtail_hosts': {
            'hosts': ['homeserver', 'circleci-runner', 'services-pi', 'webapp']
        },
        '_meta': {
            'hostvars': {
                'homeserver': {
                    'ansible_host': hosts['proxmox'],
                    'ansible_user': 'root'
                },
                'k3s-cluster': {
                    'ansible_host': hosts['k3s'],
                    'ansible_user': 'root'
                },
                'circleci-runner': {
                    'ansible_host': hosts['circleci_runner'],
                    'ansible_user': 'root'
                },
                'services-pi': {
                    'ansible_host': hosts['services_pi'],
                    'ansible_user': 'youruser'
                },
                'example-tailscale': {
                    'ansible_host': hosts['example_tailscale'],
                    'ansible_user': 'root'
                },
                'tailscale-exit-node': {
                    'ansible_host': hosts['tailscale_exit_node'],
                    'ansible_user': 'root'
                },
                'openclaw': {
                    'ansible_host': hosts['openclaw'],
                    'ansible_user': 'root'
                }
            }
        }
    }

    return inventory

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--list', action='store_true', help='List all hosts')
    parser.add_argument('--host', help='Get variables for a specific host')
    
    args = parser.parse_args()
    
    if args.list:
        inventory = get_inventory()
        print(json.dumps(inventory, indent=2))
    elif args.host:
        # Return host variables
        inventory = get_inventory()
        hostvars = inventory['_meta']['hostvars'].get(args.host, {})
        print(json.dumps(hostvars, indent=2))
    else:
        # Default to list
        inventory = get_inventory()
        print(json.dumps(inventory, indent=2))

if __name__ == '__main__':
    main()