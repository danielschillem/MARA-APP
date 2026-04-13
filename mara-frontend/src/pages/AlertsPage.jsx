import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import api from '../api';
import { buildWsUrl } from '../utils/ws';
import { MapContainer, TileLayer, CircleMarker, Popup } from 'react-leaflet';
import {
  AlertTriangle, CheckCircle, Clock, MapPin,
  User, Camera, Mic, RefreshCw, ChevronRight, X, List, Map
} from 'lucide-react';

const SEV = {
  critical: { label: 'Critique', color: '#B5103C', bg: '#FDF0F3' },
  high: { label: 'Élevé', color: '#C85A18', bg: '#FDF0E6' },
  medium: { label: 'Modéré', color: '#B87A1A', bg: '#FDF5E8' },
  low: { label: 'Faible', color: '#2D6A4F', bg: '#EAF5EE' },
};

const STATUS = {
  new: { label: 'Nouveau', color: '#B5103C', bg: '#FDF0F3' },
  assigned: { label: 'Assignée', color: '#B87A1A', bg: '#FDF5E8' },
  inprogress: { label: 'En cours', color: '#1A2E4A', bg: '#E8EFF8' },
  resolved: { label: 'Résolue', color: '#2D6A4F', bg: '#EAF5EE' },
};

const TYPE_LABELS = {
  physical: 'Violence physique',
  sexual: 'Violence sexuelle',
  verbal: 'Violence verbale',
  psych: 'Violence psychologique',
  domestic: 'Violence domestique',
  neglect: 'Négligence grave',
};

const VICTIM_LABELS = {
  woman: 'Femme adulte',
  child: 'Enfant',
  man: 'Homme adulte',
  elderly: 'Personne âgée',
  unknown: 'Inconnu(e)',
};

export default function AlertsPage() {
  const { user } = useAuth();
  const navigate = useNavigate();

  const [alerts, setAlerts] = useState([]);
  const [kpis, setKpis] = useState(null);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [selected, setSelected] = useState(null);
  const [updating, setUpdating] = useState(false);
  const [view, setView] = useState('list'); // 'list' | 'map'
  const [mapAlerts, setMapAlerts] = useState([]);
  const [mapLoading, setMapLoading] = useState(false);
  const wsRef = useRef(null);

  useEffect(() => {
    if (!user) { navigate('/login'); return; }
    loadAlerts();
    loadKpis();
    connectWS();
    return () => wsRef.current?.close();
  }, [user]);

  useEffect(() => {
    if (view === 'map') loadMapAlerts();
  }, [view]);

  async function loadMapAlerts() {
    setMapLoading(true);
    try {
      const r = await api.get('/alerts/map');
      setMapAlerts(r.data || []);
    } catch (_) { }
    finally { setMapLoading(false); }
  }

  function connectWS() {
    try {
      const wsUrl = buildWsUrl();
      const ws = new WebSocket(wsUrl);
      ws.onmessage = (e) => {
        const event = JSON.parse(e.data);
        if (event.type === 'new_alert') {
          setAlerts(prev => [event.payload, ...prev]);
          loadKpis();
        } else if (event.type === 'alert_updated' || event.type === 'alert_assigned') {
          setAlerts(prev => prev.map(a => a.id === event.payload.id ? event.payload : a));
          loadKpis();
        }
      };
      wsRef.current = ws;
    } catch (_) { }
  }

  async function loadAlerts() {
    try {
      const params = filter !== 'all' ? { status: filter } : {};
      const r = await api.get('/alerts', { params });
      setAlerts(r.data.data || r.data);
    } catch (_) { }
    finally { setLoading(false); }
  }

  async function loadKpis() {
    try {
      const r = await api.get('/alerts/dashboard');
      setKpis(r.data);
    } catch (_) { }
  }

  async function assignToMe(alertId) {
    setUpdating(true);
    try {
      await api.post(`/alerts/${alertId}/assign`);
      await loadAlerts();
      setSelected(null);
    } catch (_) { }
    finally { setUpdating(false); }
  }

  async function updateStatus(alertId, status) {
    setUpdating(true);
    try {
      await api.put(`/alerts/${alertId}`, { status });
      await loadAlerts();
      if (selected?.id === alertId) {
        const r = await api.get(`/alerts/${alertId}`);
        setSelected(r.data);
      }
    } catch (_) { }
    finally { setUpdating(false); }
  }

  const filtered = filter === 'all'
    ? alerts
    : alerts.filter(a => a.status === filter);

  const counts = {
    all: alerts.length,
    new: alerts.filter(a => a.status === 'new').length,
    assigned: alerts.filter(a => a.status === 'assigned').length,
    inprogress: alerts.filter(a => a.status === 'inprogress').length,
    resolved: alerts.filter(a => a.status === 'resolved').length,
  };

  if (!user) return null;

  return (
    <div className="section">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 24, fontWeight: 800 }}>Alertes VeilleProtect</h2>
          <p style={{ color: 'var(--text-light)', fontSize: 14 }}>Gestion des alertes citoyennes en temps réel</p>
        </div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          {/* View toggle */}
          <div style={{ display: 'flex', border: '1.5px solid var(--border)', borderRadius: 10, overflow: 'hidden' }}>
            <button
              onClick={() => setView('list')}
              style={{
                padding: '7px 14px', border: 'none', cursor: 'pointer',
                background: view === 'list' ? '#1A2E4A' : 'transparent',
                color: view === 'list' ? '#fff' : 'var(--text-light)',
                display: 'flex', alignItems: 'center', gap: 5, fontSize: 12, fontWeight: 600,
              }}
            >
              <List size={14} /> Liste
            </button>
            <button
              onClick={() => setView('map')}
              style={{
                padding: '7px 14px', border: 'none', cursor: 'pointer',
                background: view === 'map' ? '#1A2E4A' : 'transparent',
                color: view === 'map' ? '#fff' : 'var(--text-light)',
                display: 'flex', alignItems: 'center', gap: 5, fontSize: 12, fontWeight: 600,
              }}
            >
              <Map size={14} /> Carte
            </button>
          </div>
          <button onClick={() => { loadAlerts(); loadKpis(); if (view === 'map') loadMapAlerts(); }} className="btn btn-secondary" style={{ gap: 6 }}>
            <RefreshCw size={15} /> Actualiser
          </button>
        </div>
      </div>

      {/* KPI cards */}
      {kpis && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', gap: 12, marginBottom: 24 }}>
          <KpiCard label="Alertes aujourd'hui" value={kpis.today_total} color="#1A2E4A" delta="+3 dernière h." up />
          <KpiCard label="Critiques actives" value={kpis.critical_active} color="#B5103C" delta="Intervention requise" />
          <KpiCard label="Résolues" value={kpis.resolved_today} color="#2D6A4F" delta="+2 ce matin" up />
          <KpiCard label="Nouvelles" value={kpis.new} color="#B87A1A" />
          <KpiCard label="En cours" value={kpis.in_progress} color="#7A3B8C" />
          <KpiCard label="Coordinateurs" value={kpis.active_coordinators ?? 0} color="#1A2E4A" delta="actifs" up />
        </div>
      )}

      {/* Filter tabs — list view only */}
      {view === 'list' && (
        <div style={{ display: 'flex', gap: 6, marginBottom: 16, flexWrap: 'wrap' }}>
          {[
            ['all', 'Toutes'],
            ['new', 'Nouvelles'],
            ['assigned', 'Assignées'],
            ['inprogress', 'En cours'],
            ['resolved', 'Résolues'],
          ].map(([key, lbl]) => (
            <button
              key={key}
              onClick={() => setFilter(key)}
              style={{
                padding: '6px 14px', borderRadius: 20, border: 'none', cursor: 'pointer',
                fontWeight: 600, fontSize: 12,
                background: filter === key ? '#1A2E4A' : 'var(--bg-secondary)',
                color: filter === key ? '#fff' : 'var(--text-light)',
              }}
            >
              {lbl} ({counts[key] ?? 0})
            </button>
          ))}
        </div>
      )}

      {/* Alert feed — list view */}
      {view === 'list' && (
        loading ? (
          <div style={{ textAlign: 'center', padding: 60, color: 'var(--text-light)' }}>Chargement…</div>
        ) : filtered.length === 0 ? (
          <div style={{ textAlign: 'center', padding: 60, color: 'var(--text-light)' }}>Aucune alerte</div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {filtered.map(alert => (
              <AlertCard
                key={alert.id || alert.reference}
                alert={alert}
                onClick={() => setSelected(alert)}
              />
            ))}
          </div>
        )
      )}

      {/* Map view */}
      {view === 'map' && (
        <AlertMapView alerts={mapAlerts} loading={mapLoading} onSelect={setSelected} />
      )}

      {/* Alert detail modal */}
      {selected && (
        <AlertModal
          alert={selected}
          onClose={() => setSelected(null)}
          onAssign={() => assignToMe(selected.id)}
          onStatus={(s) => updateStatus(selected.id, s)}
          updating={updating}
        />
      )}
    </div>
  );
}

// ── KPI Card ────────────────────────────────────────────────────────────────

function KpiCard({ label, value, color, delta, up }) {
  return (
    <div className="card" style={{ padding: '16px', textAlign: 'left' }}>
      <div style={{ fontSize: 28, fontWeight: 800, color, fontFamily: 'var(--font-heading)' }}>{value ?? '—'}</div>
      <div style={{ fontSize: 12, color: 'var(--text-light)', marginTop: 4 }}>{label}</div>
      {delta && (
        <div style={{ fontSize: 11, marginTop: 4, color: up ? '#2D6A4F' : '#B5103C', fontWeight: 600 }}>
          {delta}
        </div>
      )}
    </div>
  );
}

// ── Alert Card ──────────────────────────────────────────────────────────────

function AlertCard({ alert, onClick }) {
  const sev = SEV[alert.severity] || SEV.medium;
  const status = STATUS[alert.status] || STATUS.new;

  return (
    <div
      className="card"
      onClick={onClick}
      style={{ padding: '14px 16px', cursor: 'pointer', transition: 'box-shadow .15s' }}
      onMouseEnter={e => e.currentTarget.style.boxShadow = '0 4px 16px rgba(0,0,0,.10)'}
      onMouseLeave={e => e.currentTarget.style.boxShadow = ''}
    >
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
        {/* Severity dot */}
        <div style={{
          width: 12, height: 12, borderRadius: '50%',
          background: sev.color, flexShrink: 0, marginTop: 5,
          boxShadow: `0 0 0 4px ${sev.bg}`
        }} />

        {/* Content */}
        <div style={{ flex: 1 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8 }}>
            <div>
              <span style={{ fontSize: 14, fontWeight: 700, color: 'var(--text-primary)' }}>
                {TYPE_LABELS[alert.type_id] || alert.type_id}
              </span>
              <span style={{ fontSize: 12, color: 'var(--text-light)', marginLeft: 8 }}>
                · {VICTIM_LABELS[alert.victim_type] || alert.victim_type}
              </span>
            </div>
            <div style={{ display: 'flex', gap: 6, flexShrink: 0 }}>
              <Badge label={sev.label} color={sev.color} bg={sev.bg} />
              <Badge label={status.label} color={status.color} bg={status.bg} />
            </div>
          </div>

          <div style={{ display: 'flex', gap: 14, marginTop: 6, flexWrap: 'wrap' }}>
            {alert.zone && (
              <span style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: 'var(--text-light)' }}>
                <MapPin size={11} /> {alert.zone}
              </span>
            )}
            {alert.coordinator && (
              <span style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: 'var(--text-light)' }}>
                <User size={11} /> {alert.coordinator.name}
              </span>
            )}
            {alert.is_ongoing && (
              <span style={{ fontSize: 11, color: '#B5103C', fontWeight: 600 }}>⚡ En cours</span>
            )}
            {alert.channel && (
              <span style={{ fontSize: 11, color: 'var(--text-light)' }}>
                via {alert.channel.toUpperCase()}
              </span>
            )}
            {alert.has_photo && <span style={{ fontSize: 11, color: 'var(--text-light)' }}><Camera size={11} /> Photo</span>}
            {alert.has_audio && <span style={{ fontSize: 11, color: 'var(--text-light)' }}><Mic size={11} /> Audio</span>}
          </div>
        </div>

        <ChevronRight size={14} style={{ color: 'var(--text-light)', flexShrink: 0, marginTop: 4 }} />
      </div>
    </div>
  );
}

// ── Alert Detail Modal ──────────────────────────────────────────────────────

function AlertModal({ alert, onClose, onAssign, onStatus, updating }) {
  const sev = SEV[alert.severity] || SEV.medium;
  const status = STATUS[alert.status] || STATUS.new;

  return (
    <div
      style={{
        position: 'fixed', inset: 0, background: 'rgba(0,0,0,.5)',
        zIndex: 1000, display: 'flex', alignItems: 'flex-end', justifyContent: 'center',
      }}
      onClick={onClose}
    >
      <div
        style={{
          background: 'var(--bg-primary)', borderRadius: '20px 20px 0 0',
          width: '100%', maxWidth: 640, maxHeight: '85vh',
          overflow: 'auto', padding: 24,
        }}
        onClick={e => e.stopPropagation()}
      >
        {/* Handle */}
        <div style={{ width: 40, height: 4, background: 'var(--border)', borderRadius: 2, margin: '0 auto 20px' }} />

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
          <div>
            <h3 style={{ fontSize: 18, fontWeight: 700 }}>
              {TYPE_LABELS[alert.type_id] || alert.type_id} · {VICTIM_LABELS[alert.victim_type] || alert.victim_type}
            </h3>
            <div style={{ display: 'flex', gap: 8, marginTop: 6 }}>
              <Badge label={sev.label} color={sev.color} bg={sev.bg} />
              <Badge label={status.label} color={status.color} bg={status.bg} />
              <span style={{ fontSize: 11, color: 'var(--text-light)' }}>
                {alert.reference}
              </span>
            </div>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 4 }}>
            <X size={20} />
          </button>
        </div>

        {/* Details grid */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 16 }}>
          {alert.zone && <Detail icon={<MapPin size={13} />} label="Zone" value={alert.zone} />}
          {alert.coordinator && <Detail icon={<User size={13} />} label="Coordinateur" value={alert.coordinator.name} />}
          <Detail icon={<Clock size={13} />} label="Canal" value={alert.channel?.toUpperCase() || 'APP'} />
          <Detail icon={<AlertTriangle size={13} />} label="Statut" value={alert.is_ongoing ? 'En cours' : 'Après les faits'} />
          {(alert.has_photo || alert.has_audio) && (
            <Detail icon={<Camera size={13} />} label="Preuves"
              value={[alert.has_photo && 'Photo', alert.has_audio && 'Audio'].filter(Boolean).join(', ')} />
          )}
          <Detail icon={<User size={13} />} label="Anonymat" value={alert.is_anonymous ? 'Anonyme' : 'Identifié(e)'} />
        </div>

        {alert.notes && (
          <div style={{
            background: 'var(--bg-secondary)', borderRadius: 12, padding: 12, marginBottom: 16,
            fontSize: 13, color: 'var(--text-secondary)', lineHeight: 1.6,
          }}>
            {alert.notes}
          </div>
        )}

        {/* Actions */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {alert.status === 'new' && (
            <button
              onClick={onAssign}
              disabled={updating}
              className="btn btn-primary"
            >
              {updating ? 'En cours…' : 'Prendre en charge'}
            </button>
          )}
          {alert.status !== 'resolved' && (
            <button
              onClick={() => onStatus('resolved')}
              disabled={updating}
              className="btn"
              style={{ background: '#EAF5EE', color: '#2D6A4F', border: '1.5px solid #2D6A4F' }}
            >
              <CheckCircle size={15} style={{ marginRight: 6 }} />
              Marquer comme résolu
            </button>
          )}
          {alert.status === 'assigned' && (
            <button
              onClick={() => onStatus('inprogress')}
              disabled={updating}
              className="btn"
              style={{ background: '#E8EFF8', color: '#1A2E4A', border: '1.5px solid #1A2E4A' }}
            >
              Passer en cours
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

function Badge({ label, color, bg }) {
  return (
    <span style={{
      padding: '2px 9px', borderRadius: 20, fontSize: 10, fontWeight: 700,
      color, background: bg, border: `1px solid ${color}30`,
    }}>
      {label}
    </span>
  );
}

function Detail({ icon, label, value }) {
  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 8, padding: '10px 12px', background: '#EAF5EE', borderRadius: 11 }}>
      <span style={{ color: '#2D6A4F', marginTop: 1 }}>{icon}</span>
      <div>
        <div style={{ fontSize: 10, color: '#888', letterSpacing: '.05em', textTransform: 'uppercase' }}>{label}</div>
        <div style={{ fontSize: 12, fontWeight: 700, color: '#2D6A4F' }}>{value}</div>
      </div>
    </div>
  );
}

// ── Map View ────────────────────────────────────────────────────────────────

// Burkina Faso center: 12.3716° N, -1.5275° E and zoom 7
const BF_CENTER = [12.3716, -1.5275];
const SEV_COLORS = {
  critical: '#B5103C',
  high: '#C85A18',
  medium: '#B87A1A',
  low: '#2D6A4F',
};

function AlertMapView({ alerts, loading, onSelect }) {
  if (loading) {
    return <div style={{ textAlign: 'center', padding: 80, color: 'var(--text-light)' }}>Chargement de la carte…</div>;
  }

  const located = alerts.filter(a => a.lat && a.lng);

  return (
    <div className="card" style={{ overflow: 'hidden', borderRadius: 16 }}>
      {/* Legend */}
      <div style={{ display: 'flex', gap: 14, padding: '10px 16px', flexWrap: 'wrap', borderBottom: '1px solid var(--border)' }}>
        <span style={{ fontSize: 11, color: 'var(--text-light)', fontWeight: 600 }}>Sévérité :</span>
        {Object.entries(SEV_COLORS).map(([sev, color]) => (
          <span key={sev} style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 11 }}>
            <span style={{ width: 10, height: 10, borderRadius: '50%', background: color, display: 'inline-block' }} />
            {SEV[sev]?.label ?? sev}
          </span>
        ))}
        <span style={{ marginLeft: 'auto', fontSize: 11, color: 'var(--text-light)' }}>
          {located.length} alerte{located.length !== 1 ? 's' : ''} géolocalisée{located.length !== 1 ? 's' : ''}
        </span>
      </div>

      <MapContainer
        center={BF_CENTER}
        zoom={7}
        style={{ height: 520, width: '100%' }}
        scrollWheelZoom
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {located.map(alert => (
          <CircleMarker
            key={alert.id}
            center={[alert.lat, alert.lng]}
            radius={alert.severity === 'critical' ? 14 : alert.severity === 'high' ? 11 : 8}
            pathOptions={{
              color: '#fff',
              weight: 2,
              fillColor: SEV_COLORS[alert.severity] || SEV_COLORS.medium,
              fillOpacity: 0.9,
            }}
            eventHandlers={{ click: () => onSelect(alert) }}
          >
            <Popup>
              <div style={{ minWidth: 180 }}>
                <div style={{ fontWeight: 700, fontSize: 13 }}>
                  {TYPE_LABELS[alert.type_id] || alert.type_id}
                </div>
                <div style={{ fontSize: 11, color: '#666', marginTop: 2 }}>
                  {VICTIM_LABELS[alert.victim_type] || alert.victim_type}
                </div>
                {alert.zone && (
                  <div style={{ fontSize: 11, marginTop: 4, color: '#444' }}>📍 {alert.zone}</div>
                )}
                {alert.is_ongoing && (
                  <div style={{ fontSize: 11, color: '#B5103C', fontWeight: 700, marginTop: 4 }}>⚡ En cours</div>
                )}
                <div style={{
                  marginTop: 8, display: 'inline-block',
                  padding: '2px 8px', borderRadius: 10, fontSize: 10, fontWeight: 700,
                  background: SEV_COLORS[alert.severity] + '22',
                  color: SEV_COLORS[alert.severity],
                  border: `1px solid ${SEV_COLORS[alert.severity]}44`,
                }}>
                  {SEV[alert.severity]?.label ?? alert.severity}
                </div>
              </div>
            </Popup>
          </CircleMarker>
        ))}
      </MapContainer>

      {located.length === 0 && !loading && (
        <div style={{ textAlign: 'center', padding: 24, color: 'var(--text-light)', fontSize: 13 }}>
          Aucune alerte avec coordonnées GPS disponible.
        </div>
      )}
    </div>
  );
}
