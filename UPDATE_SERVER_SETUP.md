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

## Simple PHP Server Example

```php
<?php
header('Content-Type: application/json');

// Get current version from request headers
$currentVersion = $_SERVER['HTTP_X_CURRENT_VERSION'] ?? '0.0.0';
$currentBuild = intval($_SERVER['HTTP_X_CURRENT_BUILD'] ?? 0);

// Define latest version information
$latestVersion = [
    'version' => '1.1.0',
    'buildNumber' => 2,
    'downloadUrl' => 'https://your-server.com/downloads/senselite-1.1.0-setup.exe',
    'checksum' => 'sha256:your-actual-sha256-checksum-here',
    'fileSize' => 52428800, // Size in bytes
    'releaseNotes' => "• Added new image annotation features\n• Fixed performance issues\n• Updated UI theme\n• Bug fixes and improvements",
    'isCritical' => false,
    'minimumVersion' => '1.0.0',
    'releaseDate' => '2025-10-08T10:00:00Z'
];

// Simple version comparison
function isNewerVersion($current, $latest) {
    return version_compare($latest, $current, '>');
}

// Check if update is available
if (isNewerVersion($currentVersion, $latestVersion['version'])) {
    http_response_code(200);
    echo json_encode($latestVersion);
} else {
    http_response_code(204); // No Content - up to date
}
?>
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