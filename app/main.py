"""
Flask application with health check and version display.
"""
import os
from flask import Flask, jsonify, render_template_string

app = Flask(__name__)

# Get app version from environment variable with fallback
APP_VERSION = os.environ.get('APP_VERSION', 'v2.0.1')
APP_NAME = os.environ.get('APP_NAME', 'Demo Flask App')


@app.route('/healthz')
def healthz():
    """Health check endpoint for Kubernetes probes."""
    return jsonify({'status': 'ok'}), 200


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


if __name__ == '__main__':
    # For local development only
    app.run(host='0.0.0.0', port=5000, debug=True)
# GitOps works
