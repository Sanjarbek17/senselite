# SenseLite Update Server Configuration

This document provides an example of how to set up an HTTP-based update server for the SenseLite application.

## Server Endpoint

The update service expects a REST API endpoint that responds to GET requests with update information in JSON format.

### Default URL Structure
```
https://your-server.com/api/updates/check
```

## API Response Format

### When Update is Available (HTTP 200)
```json
{
  "version": "1.1.0",
  "buildNumber": 2,
  "downloadUrl": "https://your-server.com/downloads/senselite-1.1.0-setup.exe",
  "checksum": "sha256:abcd1234efgh5678...",
  "fileSize": 52428800,
  "releaseNotes": "• Added new image annotation features\n• Fixed performance issues\n• Updated UI theme\n• Bug fixes and improvements",
  "isCritical": false,
  "minimumVersion": "1.0.0",
  "releaseDate": "2025-10-08T10:00:00Z"
}
```

### When No Update is Available (HTTP 204)
```
No Content
```

## Request Headers

The update service sends the following headers with each request:

```
User-Agent: SenseLite/1.0.0
Content-Type: application/json
X-Current-Version: 1.0.0
X-Current-Build: 1
```

## Django Server Example

### 1. Create Django Project Structure
```bash
pip install django djangorestframework
django-admin startproject senselite_update_server
cd senselite_update_server
python manage.py startapp updates
```

### 2. Django Settings (settings.py)
```python
# senselite_update_server/settings.py
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'your-secret-key-here'
DEBUG = False  # Set to False in production
ALLOWED_HOSTS = ['your-server.com', 'localhost']

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'updates',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'senselite_update_server.urls'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Static files configuration
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# Media files configuration for update downloads
MEDIA_URL = '/downloads/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'downloads')

# REST Framework configuration
REST_FRAMEWORK = {
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/hour'
    }
}
```

### 3. Django Models (updates/models.py)
```python
# updates/models.py
from django.db import models
from django.utils import timezone
import hashlib
import os

class ApplicationVersion(models.Model):
    version = models.CharField(max_length=20)
    build_number = models.IntegerField()
    download_url = models.URLField()
    checksum = models.CharField(max_length=64)
    file_size = models.BigIntegerField()
    release_notes = models.TextField()
    is_critical = models.BooleanField(default=False)
    minimum_version = models.CharField(max_length=20, blank=True, null=True)
    release_date = models.DateTimeField(default=timezone.now)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-build_number']
        unique_together = ['version', 'build_number']

    def __str__(self):
        return f"SenseLite v{self.version} (Build {self.build_number})"

    def save(self, *args, **kwargs):
        # Auto-calculate checksum if file exists
        if self.download_url and not self.checksum:
            self.checksum = self.calculate_checksum()
        super().save(*args, **kwargs)

    def calculate_checksum(self):
        """Calculate SHA256 checksum of the file"""
        try:
            # This is a simple example - in production, you'd want to
            # calculate the checksum of the actual file
            return "sha256:placeholder-checksum"
        except Exception:
            return ""

    def is_newer_than(self, current_version, current_build):
        """Check if this version is newer than the provided version"""
        current_parts = [int(x) for x in current_version.split('.')]
        this_parts = [int(x) for x in self.version.split('.')]
        
        # Pad with zeros if needed
        max_len = max(len(current_parts), len(this_parts))
        current_parts.extend([0] * (max_len - len(current_parts)))
        this_parts.extend([0] * (max_len - len(this_parts)))
        
        # Compare version parts
        for current, this in zip(current_parts, this_parts):
            if this > current:
                return True
            elif this < current:
                return False
        
        # If versions are equal, compare build numbers
        return self.build_number > current_build
```

### 4. Django Views (updates/views.py)
```python
# updates/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.throttling import AnonRateThrottle
from django.http import Http404
from .models import ApplicationVersion
import logging

logger = logging.getLogger(__name__)

class UpdateCheckView(APIView):
    throttle_classes = [AnonRateThrottle]
    
    def get(self, request):
        """Check for available updates"""
        try:
            # Get current version from headers
            current_version = request.META.get('HTTP_X_CURRENT_VERSION', '0.0.0')
            current_build = int(request.META.get('HTTP_X_CURRENT_BUILD', 0))
            user_agent = request.META.get('HTTP_USER_AGENT', '')
            
            logger.info(f"Update check: {user_agent} - Current: {current_version} (Build {current_build})")
            
            # Get the latest active version
            try:
                latest_version = ApplicationVersion.objects.filter(
                    is_active=True
                ).first()
            except ApplicationVersion.DoesNotExist:
                logger.warning("No active versions found")
                return Response(status=status.HTTP_204_NO_CONTENT)
            
            if not latest_version:
                return Response(status=status.HTTP_204_NO_CONTENT)
            
            # Check if update is available
            if latest_version.is_newer_than(current_version, current_build):
                update_data = {
                    'version': latest_version.version,
                    'buildNumber': latest_version.build_number,
                    'downloadUrl': latest_version.download_url,
                    'checksum': latest_version.checksum,
                    'fileSize': latest_version.file_size,
                    'releaseNotes': latest_version.release_notes,
                    'isCritical': latest_version.is_critical,
                    'minimumVersion': latest_version.minimum_version,
                    'releaseDate': latest_version.release_date.isoformat()
                }
                
                logger.info(f"Update available: {latest_version.version} for client {current_version}")
                return Response(update_data, status=status.HTTP_200_OK)
            else:
                logger.info(f"Client {current_version} is up to date")
                return Response(status=status.HTTP_204_NO_CONTENT)
                
        except ValueError as e:
            logger.error(f"Invalid build number: {e}")
            return Response(
                {'error': 'Invalid build number'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        except Exception as e:
            logger.error(f"Update check error: {e}")
            return Response(
                {'error': 'Internal server error'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class UpdateStatsView(APIView):
    """Optional: View for update statistics"""
    
    def get(self, request):
        """Get update statistics"""
        versions = ApplicationVersion.objects.filter(is_active=True)
        return Response({
            'total_versions': versions.count(),
            'latest_version': versions.first().version if versions.exists() else None,
            'latest_build': versions.first().build_number if versions.exists() else None,
        })
```

### 5. Django URLs Configuration
```python
# senselite_update_server/urls.py
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('updates.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# updates/urls.py
from django.urls import path
from .views import UpdateCheckView, UpdateStatsView

urlpatterns = [
    path('updates/check', UpdateCheckView.as_view(), name='update-check'),
    path('updates/stats', UpdateStatsView.as_view(), name='update-stats'),
]
```

### 6. Django Admin (updates/admin.py)
```python
# updates/admin.py
from django.contrib import admin
from .models import ApplicationVersion

@admin.register(ApplicationVersion)
class ApplicationVersionAdmin(admin.ModelAdmin):
    list_display = ['version', 'build_number', 'is_critical', 'is_active', 'release_date']
    list_filter = ['is_critical', 'is_active', 'release_date']
    search_fields = ['version', 'release_notes']
    readonly_fields = ['created_at', 'updated_at', 'checksum']
    
    fieldsets = (
        ('Version Information', {
            'fields': ('version', 'build_number', 'minimum_version')
        }),
        ('Download Information', {
            'fields': ('download_url', 'checksum', 'file_size')
        }),
        ('Release Information', {
            'fields': ('release_notes', 'release_date', 'is_critical', 'is_active')
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ['collapse']
        }),
    )
```

### 7. Database Migration & Setup
```bash
# Create and apply migrations
python manage.py makemigrations
python manage.py migrate

# Create superuser for admin access
python manage.py createsuperuser

# Run the development server
python manage.py runserver 0.0.0.0:8000
```

### 8. Production Deployment with Nginx
```nginx
# /etc/nginx/sites-available/senselite-updates
server {
    listen 80;
    server_name your-server.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name your-server.com;
    
    ssl_certificate /path/to/your/certificate.crt;
    ssl_certificate_key /path/to/your/private.key;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /downloads/ {
        alias /path/to/your/downloads/;
        expires 1h;
        add_header Cache-Control "public, immutable";
    }
    
    location /static/ {
        alias /path/to/your/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## Node.js Express Server Example

```javascript
const express = require('express');
const app = express();

app.get('/api/updates/check', (req, res) => {
    const currentVersion = req.headers['x-current-version'] || '0.0.0';
    const currentBuild = parseInt(req.headers['x-current-build']) || 0;
    
    const latestVersion = {
        version: '1.1.0',
        buildNumber: 2,
        downloadUrl: 'https://your-server.com/downloads/senselite-1.1.0-setup.exe',
        checksum: 'sha256:your-actual-sha256-checksum-here',
        fileSize: 52428800,
        releaseNotes: '• Added new image annotation features\n• Fixed performance issues\n• Updated UI theme\n• Bug fixes and improvements',
        isCritical: false,
        minimumVersion: '1.0.0',
        releaseDate: '2025-10-08T10:00:00Z'
    };
    
    // Simple version comparison
    if (isNewerVersion(currentVersion, latestVersion.version)) {
        res.json(latestVersion);
    } else {
        res.status(204).send(); // No Content
    }
});

function isNewerVersion(current, latest) {
    const currentParts = current.split('.').map(Number);
    const latestParts = latest.split('.').map(Number);
    
    for (let i = 0; i < 3; i++) {
        const currentPart = currentParts[i] || 0;
        const latestPart = latestParts[i] || 0;
        
        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
    }
    
    return false;
}

app.listen(3000, () => {
    console.log('Update server running on port 3000');
});
```

## Security Considerations

1. **HTTPS Only**: Always use HTTPS for update checks and downloads
2. **Checksum Verification**: Include SHA256 checksums for file integrity
3. **Code Signing**: Sign your Windows executables with a trusted certificate
4. **Rate Limiting**: Implement rate limiting to prevent abuse
5. **Authentication**: Consider adding API keys for enterprise deployments

## File Hosting

Update files can be hosted on:
- AWS S3 with CloudFront
- Azure Blob Storage
- Google Cloud Storage
- Your own web server
- GitHub Releases (for open source projects)

## Configuration in SenseLite

To configure the update URL in your SenseLite application:

1. Open Settings
2. Navigate to the Updates section
3. The app will use the default URL or you can configure it programmatically

Alternatively, modify the `_defaultUpdateUrl` constant in `update_service.dart`:

```dart
static const String _defaultUpdateUrl = 'https://your-server.com/api/updates/check';
```