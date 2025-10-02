#!/bin/bash

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y python3-pip python3-venv git nginx postgresql-client awscli

# Create application user
useradd -m -s /bin/bash django
mkdir -p /opt/app
chown django:django /opt/app

# Create virtual environment
sudo -u django python3 -m venv /opt/app/venv
source /opt/app/venv/bin/activate

# Install Python packages
pip install django gunicorn psycopg2-binary boto3

# Create a basic Django project (replace with your actual deployment)
cd /opt/app
sudo -u django /opt/app/venv/bin/django-admin startproject myproject .

# Configure Django settings for production (basic example)
cat > /opt/app/myproject/production_settings.py << 'EOF'
from .settings import *
import os

DEBUG = False
ALLOWED_HOSTS = ['*']  # Configure properly for production

# Database configuration
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': '${db_name}',
        'USER': '${db_user}',
        'PASSWORD': '${db_password}',
        'HOST': '${db_endpoint}',
        'PORT': '5432',
    }
}

# Security settings
SECURE_SSL_REDIRECT = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
EOF

# Create Gunicorn service
cat > /etc/systemd/system/gunicorn.service << 'EOF'
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=django
Group=django
WorkingDirectory=/opt/app
ExecStart=/opt/app/venv/bin/gunicorn --access-logfile - --workers 3 --bind 0.0.0.0:8000 myproject.wsgi:application
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Create health check endpoint
mkdir -p /opt/app/myproject/health
cat > /opt/app/myproject/health/__init__.py << 'EOF'
EOF

cat > /opt/app/myproject/health/views.py << 'EOF'
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods

@require_http_methods(["GET"])
def health_check(request):
    return JsonResponse({"status": "healthy", "service": "django-backend"})
EOF

cat > /opt/app/myproject/health/urls.py << 'EOF'
from django.urls import path
from . import views

urlpatterns = [
    path('', views.health_check, name='health_check'),
]
EOF

# Update main URLs
cat > /opt/app/myproject/urls.py << 'EOF'
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('health/', include('myproject.health.urls')),
]
EOF

# Set proper permissions
chown -R django:django /opt/app

# Start and enable services
systemctl daemon-reload
systemctl enable gunicorn
systemctl start gunicorn

# Configure nginx (optional - ALB handles load balancing)
systemctl enable nginx
systemctl start nginx

# Configure CloudWatch agent (optional)
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

echo "Django application setup completed"
