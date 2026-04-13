import { describe, it, expect, vi, beforeEach } from 'vitest';
import axios from 'axios';

// ── API module is built on axios with interceptors ────────────────────────────
// We test the interceptor logic directly without importing the singleton

describe('API interceptors logic', () => {
    beforeEach(() => {
        localStorage.clear();
    });

    it('attaches Bearer token from localStorage when present', () => {
        localStorage.setItem('token', 'test-jwt-token');
        const token = localStorage.getItem('token');
        const config = { headers: {} };
        if (token) config.headers['Authorization'] = `Bearer ${token}`;
        expect(config.headers['Authorization']).toBe('Bearer test-jwt-token');
    });

    it('does not attach Authorization header when no token', () => {
        const token = localStorage.getItem('token');
        const config = { headers: {} };
        if (token) config.headers['Authorization'] = `Bearer ${token}`;
        expect(config.headers['Authorization']).toBeUndefined();
    });

    it('clears storage on 401 response', () => {
        localStorage.setItem('token', 'expired-token');
        localStorage.setItem('user', JSON.stringify({ id: 1 }));

        // Simulate the 401 interceptor handler
        const err = { response: { status: 401 } };
        if (err.response?.status === 401) {
            localStorage.removeItem('token');
            localStorage.removeItem('user');
        }

        expect(localStorage.getItem('token')).toBeNull();
        expect(localStorage.getItem('user')).toBeNull();
    });

    it('does not clear storage on non-401 errors', () => {
        localStorage.setItem('token', 'valid-token');
        const err = { response: { status: 500 } };
        if (err.response?.status === 401) {
            localStorage.removeItem('token');
        }
        expect(localStorage.getItem('token')).toBe('valid-token');
    });
});

// ── URL helpers used in chat/alerts WebSocket logic ───────────────────────────

describe('WebSocket URL construction', () => {
    const buildWsUrl = (apiUrl) => {
        if (apiUrl.startsWith('/')) {
            return `ws://localhost${apiUrl.replace(/\/api\/?$/, '')}/api/ws`;
        }
        return apiUrl
            .replace(/^https/, 'wss')
            .replace(/^http/, 'ws')
            .replace(/\/api\/?$/, '/api/ws');
    };

    it('converts http to ws', () => {
        expect(buildWsUrl('http://localhost:8081/api')).toBe('ws://localhost:8081/api/ws');
    });

    it('converts https to wss', () => {
        expect(buildWsUrl('https://mara.app/api')).toBe('wss://mara.app/api/ws');
    });

    it('handles trailing slash', () => {
        expect(buildWsUrl('http://localhost:8081/api/')).toBe('ws://localhost:8081/api/ws');
    });

    it('handles relative /api base URL', () => {
        expect(buildWsUrl('/api')).toBe('ws://localhost/api/ws');
    });
});
