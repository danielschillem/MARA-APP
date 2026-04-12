import { createContext, useContext, useState, useCallback } from 'react';
import { CheckCircle, AlertTriangle, X, Info } from 'lucide-react';

const ToastContext = createContext(null);

const TOAST_ICONS = {
  success: CheckCircle,
  error: AlertTriangle,
  info: Info,
  warning: AlertTriangle,
};

const TOAST_COLORS = {
  success: { bg: '#e8f5e9', border: 'var(--success)', color: 'var(--success)' },
  error: { bg: '#ffebee', border: 'var(--danger)', color: 'var(--danger)' },
  info: { bg: 'var(--purple-xlight)', border: 'var(--purple)', color: 'var(--purple)' },
  warning: { bg: '#fff8e1', border: 'var(--warning)', color: 'var(--warning)' },
};

export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);

  const addToast = useCallback((message, type = 'info', duration = 4000) => {
    const id = Date.now() + Math.random();
    setToasts(prev => [...prev, { id, message, type }]);
    if (duration > 0) {
      setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), duration);
    }
  }, []);

  const removeToast = useCallback((id) => {
    setToasts(prev => prev.filter(t => t.id !== id));
  }, []);

  return (
    <ToastContext.Provider value={{ addToast }}>
      {children}
      <div style={{ position: 'fixed', top: 80, right: 20, zIndex: 9998, display: 'flex', flexDirection: 'column', gap: 8, maxWidth: 360 }}>
        {toasts.map(toast => {
          const Icon = TOAST_ICONS[toast.type] || Info;
          const colors = TOAST_COLORS[toast.type] || TOAST_COLORS.info;
          return (
            <div key={toast.id} className="toast-item" style={{
              background: colors.bg, borderLeft: `4px solid ${colors.border}`,
              padding: '12px 16px', borderRadius: 8, display: 'flex', alignItems: 'center', gap: 10,
              boxShadow: '0 4px 16px rgba(0,0,0,0.12)', animation: 'toast-in 0.3s ease',
              fontSize: 13, fontFamily: 'Poppins, sans-serif'
            }}>
              <Icon size={18} color={colors.color} style={{ flexShrink: 0 }} />
              <span style={{ flex: 1, color: 'var(--text)' }}>{toast.message}</span>
              <button onClick={() => removeToast(toast.id)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 2, color: 'var(--text-light)' }}
                aria-label="Fermer">
                <X size={14} />
              </button>
            </div>
          );
        })}
      </div>
    </ToastContext.Provider>
  );
}

export const useToast = () => useContext(ToastContext);
