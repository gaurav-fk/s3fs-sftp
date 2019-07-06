## How to deploy to prod

This role has grown into a generic role for all SFTP setup across env and components.

ansible-playbook sftp.yml -e target=all -i "<host>", -e app_env=prod -e component=test

