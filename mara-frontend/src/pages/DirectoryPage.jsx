import { useState, useEffect, useMemo } from 'react';
import api from '../api';
import { Phone, MapPin, Clock, Shield, Heart, Building, Stethoscope, Scale, Siren, Search, X, ExternalLink, Mail, Globe, ChevronRight, Filter } from 'lucide-react';
import DynamicIcon from '../components/DynamicIcon';
import IconBadge from '../components/IconBadge';

const TYPE_CONFIG = {
  securite: { icon: <Shield size={20} />, label: 'Sécurité', color: '#3498db', bg: '#E3F2FD' },
  ong: { icon: <Heart size={20} />, label: 'ONG / Association', color: '#e74c3c', bg: '#FFEBEE' },
  institutionnel: { icon: <Building size={20} />, label: 'Institutionnel', color: '#9b59b6', bg: '#EDE0FA' },
  medical: { icon: <Stethoscope size={20} />, label: 'Médical', color: '#27ae60', bg: '#E8F5E9' },
  urgence: { icon: <Siren size={20} />, label: 'Urgence', color: '#e74c3c', bg: '#FFEBEE' },
  juridique: { icon: <Scale size={20} />, label: 'Juridique', color: '#f39c12', bg: '#FFF8E1' },
};

const REGIONS = [
  'Centre', 'Hauts-Bassins', 'Centre-Ouest', 'Centre-Nord', 'Nord',
  'Est', 'Sahel', 'Sud-Ouest', 'Boucle du Mouhoun', 'Cascades',
  'Centre-Est', 'Centre-Sud', 'Plateau Central',
];

export default function DirectoryPage() {
  const [services, setServices] = useState([]);
  const [sosNumbers, setSosNumbers] = useState([]);
  const [typeFilter, setTypeFilter] = useState('');
  const [regionFilter, setRegionFilter] = useState('');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState(null);

  useEffect(() => {
    Promise.all([
      api.get('/services'),
      api.get('/sos-numbers'),
    ]).then(([sRes, nRes]) => {
      setServices(sRes.data);
      setSosNumbers(nRes.data);
    }).catch(() => {}).finally(() => setLoading(false));
  }, []);

  const filtered = useMemo(() => {
    let list = services;
    if (typeFilter) list = list.filter(s => s.type === typeFilter);
    if (regionFilter) list = list.filter(s => s.region === regionFilter);
    if (search.trim()) {
      const q = search.toLowerCase().trim();
      list = list.filter(s =>
        s.name.toLowerCase().includes(q) ||
        (s.address || '').toLowerCase().includes(q) ||
        (s.phone || '').includes(q) ||
        (s.description || '').toLowerCase().includes(q)
      );
    }
    return list;
  }, [services, typeFilter, regionFilter, search]);

  const regionCounts = useMemo(() => {
    const counts = {};
    services.forEach(s => { if (s.region) counts[s.region] = (counts[s.region] || 0) + 1; });
    return counts;
  }, [services]);

  return (
    <div className="section">
      <div className="section-title">
        <h2>Annuaire des services</h2>
        <p>Trouvez les structures d'aide proches de vous au Burkina Faso</p>
      </div>

      {/* SOS Numbers — prominent */}
      <div style={{
        background: 'linear-gradient(135deg, #D32F2F, #B71C1C)',
        borderRadius: 16, padding: 24, marginBottom: 32, color: 'white'
      }}>
        <h3 style={{ fontSize: 18, fontWeight: 700, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
          <Phone size={20} /> Numéros d'urgence — Appelez maintenant
        </h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 12 }}>
          {sosNumbers.map(n => (
            <a key={n.id} href={`tel:${n.number.replace(/\s/g, '')}`}
              style={{
                background: 'rgba(255,255,255,0.15)', borderRadius: 12, padding: '14px 16px',
                display: 'flex', alignItems: 'center', gap: 12, textDecoration: 'none', color: 'white',
                transition: 'background .2s', cursor: 'pointer'
              }}
              onMouseEnter={e => e.currentTarget.style.background = 'rgba(255,255,255,0.25)'}
              onMouseLeave={e => e.currentTarget.style.background = 'rgba(255,255,255,0.15)'}
            >
              <div style={{ width: 44, height: 44, borderRadius: '50%', background: 'rgba(255,255,255,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <DynamicIcon name={n.icon} size={20} color="#fff" />
              </div>
              <div>
                <div style={{ fontWeight: 700, fontSize: 13 }}>{n.label}</div>
                <div style={{ fontSize: 11, opacity: 0.8 }}>{n.description}</div>
                <div style={{ fontWeight: 900, fontSize: 20, marginTop: 2 }}>{n.number}</div>
              </div>
            </a>
          ))}
        </div>
      </div>

      {/* Search + Filters bar */}
      <div style={{
        display: 'flex', gap: 12, flexWrap: 'wrap', marginBottom: 24,
        background: 'var(--card-bg)', border: '1px solid var(--border)', borderRadius: 12, padding: 16
      }}>
        <div style={{ flex: '1 1 250px', position: 'relative' }}>
          <Search size={16} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-light)' }} />
          <input
            type="text"
            placeholder="Rechercher un service, adresse, téléphone..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            style={{
              width: '100%', padding: '10px 12px 10px 36px', border: '1px solid var(--border)',
              borderRadius: 8, fontSize: 14, background: 'var(--bg)'
            }}
          />
        </div>
        <select value={typeFilter} onChange={e => setTypeFilter(e.target.value)}
          style={{ padding: '10px 14px', border: '1px solid var(--border)', borderRadius: 8, fontSize: 13, background: 'var(--bg)', minWidth: 140 }}>
          <option value="">Tous les types</option>
          {Object.entries(TYPE_CONFIG).map(([k, v]) => <option key={k} value={k}>{v.label}</option>)}
        </select>
        <select value={regionFilter} onChange={e => setRegionFilter(e.target.value)}
          style={{ padding: '10px 14px', border: '1px solid var(--border)', borderRadius: 8, fontSize: 13, background: 'var(--bg)', minWidth: 140 }}>
          <option value="">Toutes les régions</option>
          {REGIONS.map(r => <option key={r} value={r}>{r} {regionCounts[r] ? `(${regionCounts[r]})` : ''}</option>)}
        </select>
        {(search || typeFilter || regionFilter) && (
          <button onClick={() => { setSearch(''); setTypeFilter(''); setRegionFilter(''); }}
            className="btn btn-outline" style={{ padding: '10px 14px', fontSize: 13 }}>
            <X size={14} /> Réinitialiser
          </button>
        )}
      </div>

      {/* Results count */}
      <div style={{ marginBottom: 16, fontSize: 14, color: 'var(--text-light)', display: 'flex', alignItems: 'center', gap: 8 }}>
        <Filter size={14} />
        <span><strong>{filtered.length}</strong> service{filtered.length !== 1 ? 's' : ''} trouvé{filtered.length !== 1 ? 's' : ''}</span>
      </div>

      {loading ? (
        <p style={{ textAlign: 'center', color: 'var(--text-light)', padding: 40 }}>Chargement...</p>
      ) : (
        <div className="grid-3">
          {filtered.map(s => {
            const cfg = TYPE_CONFIG[s.type] || {};
            return (
              <div key={s.id} className="card" style={{ cursor: 'pointer', transition: 'transform .15s, box-shadow .15s' }}
                onClick={() => setSelected(s)}
                onMouseEnter={e => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 8px 24px rgba(0,0,0,0.1)'; }}
                onMouseLeave={e => { e.currentTarget.style.transform = ''; e.currentTarget.style.boxShadow = ''; }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
                  <IconBadge color={cfg.color} bg={cfg.bg} size="sm">{cfg.icon}</IconBadge>
                  <span className="badge" style={{ background: cfg.bg, color: cfg.color }}>{cfg.label}</span>
                  {s.is_free && <span className="badge badge-success">Gratuit</span>}
                  {s.is_24h && <span className="badge badge-danger">24h/24</span>}
                </div>
                <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 6 }}>{s.name}</h3>
                {s.description && <p style={{ fontSize: 12, color: 'var(--text-light)', marginBottom: 8, lineHeight: 1.4, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{s.description}</p>}
                {s.region && <p style={{ fontSize: 12, color: 'var(--text-light)', display: 'flex', alignItems: 'center', gap: 4, marginBottom: 4 }}><MapPin size={12} /> {s.region}{s.address ? ` — ${s.address}` : ''}</p>}
                {s.phone && (
                  <a href={`tel:${s.phone.replace(/\s/g, '')}`}
                    onClick={e => e.stopPropagation()}
                    style={{ fontSize: 14, fontWeight: 600, color: 'var(--purple)', marginTop: 8, display: 'flex', alignItems: 'center', gap: 4, textDecoration: 'none' }}>
                    <Phone size={14} /> {s.phone}
                  </a>
                )}
                {s.hours && <p style={{ fontSize: 12, color: 'var(--text-light)', marginTop: 4, display: 'flex', alignItems: 'center', gap: 4 }}><Clock size={12} /> {s.hours}</p>}
                <div style={{ marginTop: 8, fontSize: 12, color: 'var(--purple)', display: 'flex', alignItems: 'center', gap: 4 }}>
                  Voir détails <ChevronRight size={12} />
                </div>
              </div>
            );
          })}
          {filtered.length === 0 && (
            <div style={{ gridColumn: '1 / -1', textAlign: 'center', padding: 40 }}>
              <Search size={40} style={{ color: 'var(--text-light)', marginBottom: 12 }} />
              <p style={{ color: 'var(--text-light)', fontSize: 15 }}>Aucun service trouvé avec ces critères</p>
              <button onClick={() => { setSearch(''); setTypeFilter(''); setRegionFilter(''); }}
                className="btn btn-outline" style={{ marginTop: 12 }}>Réinitialiser les filtres</button>
            </div>
          )}
        </div>
      )}

      {/* Detail Modal */}
      {selected && (() => {
        const cfg = TYPE_CONFIG[selected.type] || {};
        const infoBg = 'var(--bg, #f8f9fa)';
        const infoStyle = {
          display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px',
          background: infoBg, borderRadius: 10, fontSize: 14, minHeight: 48,
        };
        const iconStyle = { color: 'var(--text-light)', flexShrink: 0 };
        return (
        <div style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 1000,
          display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16
        }} onClick={() => setSelected(null)}>
          <div style={{
            background: 'var(--card-bg)', borderRadius: 16, maxWidth: 520, width: '100%',
            maxHeight: '90vh', display: 'flex', flexDirection: 'column'
          }} onClick={e => e.stopPropagation()}>
            {/* Header */}
            <div style={{
              background: cfg.bg || '#f5f5f5',
              padding: '20px 24px', borderRadius: '16px 16px 0 0',
              position: 'relative', flexShrink: 0
            }}>
              <button onClick={() => setSelected(null)}
                style={{
                  position: 'absolute', top: 12, right: 12,
                  background: 'rgba(0,0,0,0.1)', border: 'none', borderRadius: '50%',
                  width: 32, height: 32, cursor: 'pointer',
                  display: 'flex', alignItems: 'center', justifyContent: 'center'
                }}>
                <X size={16} />
              </button>
              <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 10 }}>
                <IconBadge color={cfg.color} bg="white" size="lg">
                  {cfg.icon}
                </IconBadge>
                <h2 style={{ fontSize: 18, fontWeight: 800, lineHeight: 1.3, paddingRight: 32 }}>{selected.name}</h2>
              </div>
              <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginLeft: 58 }}>
                <span className="badge" style={{ background: 'white', color: cfg.color }}>
                  {cfg.label}
                </span>
                {selected.is_free && <span className="badge badge-success">Gratuit</span>}
                {selected.is_24h && <span className="badge badge-danger">24h/24</span>}
              </div>
            </div>

            {/* Body */}
            <div style={{ padding: 24, overflowY: 'auto', flex: 1 }}>
              {selected.description && (
                <p style={{
                  fontSize: 14, color: 'var(--text)', lineHeight: 1.6,
                  marginBottom: 20, paddingBottom: 16,
                  borderBottom: '1px solid var(--border, #eee)'
                }}>{selected.description}</p>
              )}

              <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                {selected.phone && (
                  <a href={`tel:${selected.phone.replace(/\s/g, '')}`}
                    style={{
                      ...infoStyle,
                      background: 'var(--purple-xlight, #f3e8ff)', color: 'var(--purple)',
                      fontWeight: 600, fontSize: 16, textDecoration: 'none'
                    }}>
                    <Phone size={20} style={{ flexShrink: 0 }} />
                    <span>{selected.phone}</span>
                  </a>
                )}

                {selected.address && (
                  <div style={infoStyle}>
                    <MapPin size={18} style={iconStyle} />
                    <span>{selected.address}{selected.region ? `, ${selected.region}` : ''}</span>
                  </div>
                )}

                {selected.hours && (
                  <div style={infoStyle}>
                    <Clock size={18} style={iconStyle} />
                    <span>{selected.hours}</span>
                  </div>
                )}

                {selected.email && (
                  <a href={`mailto:${selected.email}`}
                    style={{ ...infoStyle, textDecoration: 'none', color: 'var(--text)' }}>
                    <Mail size={18} style={iconStyle} />
                    <span style={{ wordBreak: 'break-all' }}>{selected.email}</span>
                  </a>
                )}

                {selected.website && (
                  <a href={selected.website} target="_blank" rel="noopener noreferrer"
                    style={{ ...infoStyle, textDecoration: 'none', color: 'var(--purple)' }}>
                    <Globe size={18} style={{ flexShrink: 0 }} />
                    <span style={{ flex: 1, wordBreak: 'break-all' }}>{selected.website}</span>
                    <ExternalLink size={14} style={{ flexShrink: 0, opacity: 0.6 }} />
                  </a>
                )}
              </div>

              {/* Call to action */}
              {selected.phone && (
                <a href={`tel:${selected.phone.replace(/\s/g, '')}`}
                  className="btn btn-primary"
                  style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, width: '100%', marginTop: 24, padding: '14px 0', fontSize: 15 }}>
                  <Phone size={18} /> Appeler maintenant
                </a>
              )}
            </div>
          </div>
        </div>
        );
      })()}
    </div>
  );
}
