/**
 * Build a WebSocket URL from the configured API base URL.
 * Handles both absolute URLs (http/https) and relative paths (/api).
 *
 * @param {string} [room] - Optional room query param (e.g. "conv:1")
 * @returns {string} Fully qualified ws:// or wss:// URL
 */
export function buildWsUrl(room) {
    const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8081/api';
    let wsUrl;

    if (apiUrl.startsWith('/')) {
        // Relative URL — derive scheme and host from current page
        const proto = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const base = apiUrl.replace(/\/api\/?$/, '');
        wsUrl = `${proto}//${window.location.host}${base}/api/ws`;
    } else {
        wsUrl = apiUrl
            .replace(/^https/, 'wss')
            .replace(/^http/, 'ws')
            .replace(/\/api\/?$/, '/api/ws');
    }

    return room ? `${wsUrl}?room=${room}` : wsUrl;
}
