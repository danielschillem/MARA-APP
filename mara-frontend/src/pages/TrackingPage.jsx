import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import api from '../api';
import { Search, Clock, AlertTriangle, CheckCircle, FileText, XCircle, Lock, RefreshCw } from 'lucide-react';
import { SpeakButton } from '../components/TextToSpeech';

const STATUS_ICONS = {
  nouveau: { color: '#2196F3', bg: '#e3f2fd', icon: Clock },
  en_cours: { color: 'var(--purple)', bg: 'var(--purple-xlight)', icon: RefreshCw },
  urgent: { color: 'var(--orange)', bg: '#fff3e0', icon: AlertTriangle },
  resolu: { color: 'var(--success)', bg: '#e8f5e9', icon: CheckCircle },
  cloture: { color: 'var(--text-light)', bg: '#f5f5f5', icon: Lock },
};

const PRIORITY_COLORS = {
  basse: 'var(--text-light)',
  moyenne: '#2196F3',
  haute: 'var(--orange)',
  critique: 'var(--danger)',
};

export default function TrackingPage() {
  const { t } = useTranslation();
  const [ref, setRef] = useState('');
  const [result, setResult] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSearch = async (e) => {
    e.preventDefault();
    const trimmed = ref.trim().toUpperCase();
    if (!trimmed) return;
    setError('');
    setResult(null);
    setLoading(true);
    try {
      const { data } = await api.get(`/reports/track/${encodeURIComponent(trimmed)}`);
      setResult(data);
    } catch (err) {
      if (err.response?.status === 404) {
        setError(t('tracking.notFound'));
      } else {
        setError(t('tracking.serverError'));
      }
    } finally {
      setLoading(false);
    }
  };

  const sConf = result ? (STATUS_ICONS[result.status] || STATUS_ICONS.nouveau) : null;
  const statusLabel = result ? t(`tracking.statusConfig.${result.status}`) : '';
  const priorityLabel = result ? t(`tracking.priorityConfig.${result.priority}`) : '';
  const priorityColor = result ? (PRIORITY_COLORS[result.priority] || PRIORITY_COLORS.moyenne) : '';
  const StatusIcon = sConf?.icon || Clock;

  return (
    <div className="section" style={{ maxWidth: 600 }}>
      <div className="section-title">
        <h2>{t('tracking.title')} <SpeakButton text={t('tracking.title')} size={18} /></h2>
        <p>{t('tracking.subtitle')} <SpeakButton text={t('tracking.subtitle')} size={14} /></p>
      </div>

      <form onSubmit={handleSearch} className="card">
        <div className="form-group">
          <label className="form-label">{t('tracking.refLabel')} <SpeakButton text={t('tracking.refLabel')} size={14} /></label>
          <div style={{ display: 'flex', gap: 8 }}>
            <input
              className="form-input"
              type="text"
              placeholder={t('tracking.refPlaceholder')}
              value={ref}
              onChange={e => setRef(e.target.value)}
              style={{ flex: 1, textTransform: 'uppercase', letterSpacing: 1 }}
            />
            <button className="btn btn-primary" type="submit" disabled={loading || !ref.trim()} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <Search size={16} /> {loading ? '...' : t('tracking.search')}
            </button>
          </div>
        </div>
      </form>

      {error && (
        <div className="card" style={{ marginTop: 16, background: '#ffebee', border: '1px solid var(--danger)' }}>
          <p style={{ color: 'var(--danger)', fontSize: 14, textAlign: 'center' }}>{error}</p>
        </div>
      )}

      {result && (
        <div className="card" style={{ marginTop: 16 }}>
          {/* Visual status hero */}
          <div style={{ textAlign: 'center', marginBottom: 20 }}>
            <div style={{ width: 80, height: 80, borderRadius: '50%', background: sConf.bg, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 8 }}>
              <StatusIcon size={40} color={sConf.color} />
            </div>
            <h3 style={{ color: sConf.color, marginBottom: 4 }}>
              {statusLabel} <SpeakButton text={statusLabel} size={16} />
            </h3>
            <p style={{ fontSize: 13, color: 'var(--text-light)' }}>{t('tracking.reference')} : <strong>{result.reference}</strong></p>
          </div>

          {/* Progress bar visual */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginBottom: 20, padding: '0 8px' }}>
            {['nouveau', 'en_cours', 'resolu', 'cloture'].map((st, i) => {
              const isUrgent = result.status === 'urgent';
              const steps = isUrgent ? ['nouveau', 'urgent', 'en_cours', 'resolu'] : ['nouveau', 'en_cours', 'resolu', 'cloture'];
              const currentIdx = steps.indexOf(result.status);
              const stConf = STATUS_ICONS[isUrgent ? steps[i] : st] || STATUS_ICONS.nouveau;
              const active = i <= currentIdx;
              return (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                  <div style={{
                    width: '100%', height: 6, borderRadius: 3,
                    background: active ? stConf.color : 'var(--border)',
                    transition: 'background 0.3s',
                  }} />
                  <stConf.icon size={16} color={active ? stConf.color : 'var(--text-light)'} />
                </div>
              );
            })}
          </div>

          <div style={{ display: 'grid', gap: 12 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0', borderBottom: '1px solid var(--border)' }}>
              <span style={{ color: 'var(--text-light)', fontSize: 13 }}>{t('tracking.status')}</span>
              <span className="badge" style={{ background: sConf.bg, color: sConf.color, display: 'flex', alignItems: 'center', gap: 4 }}>
                <StatusIcon size={12} color={sConf.color} /> {statusLabel}
              </span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0', borderBottom: '1px solid var(--border)' }}>
              <span style={{ color: 'var(--text-light)', fontSize: 13 }}>{t('tracking.priority')}</span>
              <strong style={{ fontSize: 13, color: priorityColor }}>{priorityLabel}</strong>
            </div>
            {result.region && (
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0', borderBottom: '1px solid var(--border)' }}>
                <span style={{ color: 'var(--text-light)', fontSize: 13 }}>{t('tracking.region')}</span>
                <strong style={{ fontSize: 13 }}>{result.region}</strong>
              </div>
            )}
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0', borderBottom: '1px solid var(--border)' }}>
              <span style={{ color: 'var(--text-light)', fontSize: 13 }}>{t('tracking.reportDate')}</span>
              <strong style={{ fontSize: 13 }}>{new Date(result.created_at).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' })}</strong>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0' }}>
              <span style={{ color: 'var(--text-light)', fontSize: 13 }}>{t('tracking.lastUpdate')}</span>
              <strong style={{ fontSize: 13 }}>{new Date(result.updated_at).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' })}</strong>
            </div>
          </div>

          <div style={{ marginTop: 20, background: sConf.bg, padding: 14, borderRadius: 8, fontSize: 13, color: 'var(--text)', lineHeight: 1.6, border: `1px solid ${sConf.color}22` }}>
            <strong>{t('tracking.statusExplain')}</strong>
            <SpeakButton text={t(`tracking.explanations.${result.status}`)} size={14} style={{ marginLeft: 6 }} />
            <br />
            {t(`tracking.explanations.${result.status}`)}
          </div>
        </div>
      )}
    </div>
  );
}
