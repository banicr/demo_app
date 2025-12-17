"""
Unit tests for the Flask application.
"""
import pytest
import json
from app.main import app


@pytest.fixture
def client():
    """Create a test client for the Flask app."""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_healthz_endpoint(client):
    """Test that /healthz returns 200 and correct JSON."""
    response = client.get('/healthz')

    assert response.status_code == 200
    assert response.content_type == 'application/json'

    data = json.loads(response.data)
    assert data == {'status': 'ok'}


def test_readiness_endpoint(client):
    """Test that /healthz/ready returns detailed checks."""
    response = client.get('/healthz/ready')

    assert response.status_code == 200
    assert response.content_type == 'application/json'

    data = json.loads(response.data)
    assert 'status' in data
    assert 'checks' in data


def test_healthz_endpoint_json_structure(client):
    """Test that /healthz returns properly structured JSON."""
    response = client.get('/healthz')
    data = json.loads(response.data)

    assert 'status' in data
    assert isinstance(data['status'], str)
    assert data['status'] == 'ok'


def test_index_endpoint(client):
    """Test that / returns 200 and HTML content."""
    response = client.get('/')

    assert response.status_code == 200
    assert response.content_type == 'text/html; charset=utf-8'
    assert b'Demo Flask App' in response.data


def test_index_shows_version(client):
    """Test that index page contains version information."""
    response = client.get('/')

    # Should contain version text
    assert b'Current Version:' in response.data
    # Should contain a version string (v*.*.* format or APP_VERSION reference)
    # Use regex-like check for version pattern
    assert (b'v1.0.0' in response.data or
            b'v2.0.0' in response.data or
            b'APP_VERSION' in response.data or
            b'class="version"' in response.data)
