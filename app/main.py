"""
Flask application with health check and version display.
"""
import os
import psutil
from flask import Flask, jsonify, render_template_string

app = Flask(__name__)

# Get app version from environment variable with fallback
APP_VERSION = os.environ.get('APP_VERSION', 'v2.0.1')
APP_NAME = os.environ.get('APP_NAME', 'Demo Flask App')


@app.route('/healthz')
def healthz():
    """
    Legacy health check endpoint for backward compatibility.
    Redirects to readiness check.
    """
    return readiness()


@app.route('/healthz/live')
def liveness():
    """
    Liveness probe endpoint - checks if the process is alive.
    Returns 200 if the Flask process is running.
    Kubernetes will restart the pod if this fails.
    """
    return jsonify({'status': 'ok', 'check': 'liveness'}), 200


@app.route('/healthz/ready')
def readiness():
    """
    Readiness probe endpoint - checks if the app can serve traffic.
    Performs comprehensive health checks including memory usage.
    Kubernetes will remove pod from service if this fails.
    """
    checks = {}
    status_code = 200

    # Check memory usage
    try:
        memory = psutil.virtual_memory()
        memory_percent = memory.percent

        if memory_percent > 90:
            checks['memory'] = f'critical: {memory_percent:.1f}%'
            status_code = 503
        elif memory_percent > 80:
            checks['memory'] = f'warning: {memory_percent:.1f}%'
        else:
            checks['memory'] = f'ok: {memory_percent:.1f}%'
    except Exception as e:
        checks['memory'] = f'error: {str(e)}'
        status_code = 503

    # Check disk usage
    try:
        disk = psutil.disk_usage('/')
        disk_percent = disk.percent

        if disk_percent > 90:
            checks['disk'] = f'critical: {disk_percent:.1f}%'
            status_code = 503
        elif disk_percent > 80:
            checks['disk'] = f'warning: {disk_percent:.1f}%'
        else:
            checks['disk'] = f'ok: {disk_percent:.1f}%'
    except Exception as e:
        checks['disk'] = f'error: {str(e)}'
        # Don't fail on disk check errors in containers

    # Check if Flask app is responding
    checks['flask'] = 'ok'

    overall_status = 'ready' if status_code == 200 else 'not ready'
    
    return jsonify({
        'status': overall_status,
        'checks': checks
    }), status_code


@app.route('/')
def index():
    """Root endpoint showing app name and version."""
    html_template = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>{{ app_name }}</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
            }
            .container {
                background: rgba(255, 255, 255, 0.1);
                padding: 40px;
                border-radius: 10px;
                box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
                backdrop-filter: blur(4px);
                border: 1px solid rgba(255, 255, 255, 0.18);
            }
            h1 {
                margin-top: 0;
            }
            .version {
                font-size: 24px;
                font-weight: bold;
                color: #ffd700;
            }
            .info {
                margin-top: 20px;
                font-size: 14px;
                opacity: 0.8;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 {{ app_name }}</h1>
            <p>Current Version: <span class="version">{{ version }}</span></p>
            <div class="info">
                <p>✓ GitOps-managed deployment</p>
                <p>✓ CI/CD with GitHub Actions</p>
                <p>✓ ArgoCD synchronization</p>
            </div>
        </div>
    </body>
    </html>
    """
    return render_template_string(
        html_template,
        app_name=APP_NAME,
        version=APP_VERSION
    )


@app.errorhandler(404)
def not_found(e):
    """Handle 404 errors."""
    return jsonify({'error': 'Not found', 'status': 404}), 404


@app.errorhandler(500)
def internal_error(e):
    """Handle 500 errors."""
    return jsonify({'error': 'Internal server error', 'status': 500}), 500


if __name__ == '__main__':
    # For local development only
    app.run(host='0.0.0.0', port=5000, debug=True)
