import { useEffect, useRef, useCallback } from 'react';
import { useAuth } from '../contexts/AuthContext';

const WS_BASE = import.meta.env.VITE_WS_URL || (
    window.location.protocol === 'https:' ? 'wss:' : 'ws:'
) + '//' + window.location.host + '/api/ws';

/**
 * Connects to the MARA WebSocket server and dispatches custom DOM events
 * for real-time notifications. Reconnects automatically with exponential backoff.
 *
 * Usage: useWsNotifications((event) => showToast(event.type, event.payload))
 */
export function useWsNotifications(onEvent) {
    const { user } = useAuth();
    const wsRef = useRef(null);
    const retryRef = useRef(0);
    const timerRef = useRef(null);
    const onEventRef = useRef(onEvent);
    onEventRef.current = onEvent;

    const connect = useCallback(() => {
        if (!user) return;

        const token = localStorage.getItem('token');
        const room = 'global';
        const url = `${WS_BASE}?room=${room}${token ? `&token=${token}` : ''}`;

        try {
            const ws = new WebSocket(url);
            wsRef.current = ws;

            ws.onopen = () => {
                retryRef.current = 0; // reset backoff on success
            };

            ws.onmessage = (e) => {
                try {
                    const event = JSON.parse(e.data);
                    if (onEventRef.current) onEventRef.current(event);
                } catch { /* ignore malformed */ }
            };

            ws.onclose = () => {
                // Exponential backoff: 1s, 2s, 4s, 8s … max 30s
                const delay = Math.min(1000 * 2 ** retryRef.current, 30000);
                retryRef.current++;
                timerRef.current = setTimeout(connect, delay);
            };

            ws.onerror = () => {
                ws.close();
            };
        } catch { /* WebSocket not available (SSR) */ }
    }, [user]);

    useEffect(() => {
        connect();
        return () => {
            clearTimeout(timerRef.current);
            wsRef.current?.close();
        };
    }, [connect]);
}
