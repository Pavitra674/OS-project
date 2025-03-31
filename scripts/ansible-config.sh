#!/bin/sh
# OS-project: Ansible Configuration

# Install Ansible
echo "Installing Ansible..."
apk add ansible

# Create Ansible configuration directory
mkdir -p /etc/ansible/examples

# Create a sample inventory file
cat > /etc/ansible/examples/inventory.ini << EOF
[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com
db2.example.com

[cloud:children]
webservers
dbservers
EOF

# Create a sample playbook
cat > /etc/ansible/examples/setup-webserver.yml << EOF
---
- name: Setup Web Servers
  hosts: webservers
  become: yes
  
  tasks:
    - name: Install Nginx
      package:
        name: nginx
        state: present
      
    - name: Start Nginx service
      service:
        name: nginx
        state: started
        enabled: yes
      
    - name: Create web directory
      file:
        path: /var/www/html
        state: directory
        mode: '0755'
      
    - name: Copy sample index file
      copy:
        content: "<html><body><h1>Hello from OS-project!</h1></body></html>"
        dest: /var/www/html/index.html
EOF

# Create another sample playbook for database servers
cat > /etc/ansible/examples/setup-dbserver.yml << EOF
---
- name: Setup Database Servers
  hosts: dbservers
  become: yes
  
  tasks:
    - name: Install PostgreSQL
      package:
        name: postgresql
        state: present
      
    - name: Start PostgreSQL service
      service:
        name: postgresql
        state: started
        enabled: yes
      
    - name: Create database user
      postgresql_user:
        name: osproject
        password: securepassword
        state: present
        role_attr_flags: CREATEDB,LOGIN
      become: yes
      become_user: postgres
      
    - name: Create database
      postgresql_db:
        name: osprojectdb
        owner: osproject
        state: present
      become: yes
      become_user: postgres
EOF

# Create a combined playbook
cat > /etc/ansible/examples/setup-all.yml << EOF
---
- import_playbook: setup-webserver.yml
- import_playbook: setup-dbserver.yml
EOF

echo "Ansible configured successfully with example playbooks!"
