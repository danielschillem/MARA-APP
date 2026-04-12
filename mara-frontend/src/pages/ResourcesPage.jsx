import { useState, useEffect, useRef } from 'react';
import api from '../api';
import { Newspaper, Video, ScrollText, FileCheck, BarChart3, Presentation, Search, X, ExternalLink, Clock, Tag, ChevronLeft, ChevronRight, BookOpen, Volume2, Play, Pause } from 'lucide-react';
import IconBadge from '../components/IconBadge';

const TYPE_ICONS = {
  article:      { icon: <Newspaper size={18} />,      color: '#2196F3', bg: '#E3F2FD' },
  video:        { icon: <Video size={18} />,           color: '#E74C3C', bg: '#FFEBEE' },
  loi:          { icon: <ScrollText size={18} />,      color: '#F39C12', bg: '#FFF8E1' },
  guide:        { icon: <FileCheck size={18} />,       color: '#27AE60', bg: '#E8F5E9' },
  infographie:  { icon: <BarChart3 size={18} />,       color: '#9B59B6', bg: '#EDE0FA' },
  formation:    { icon: <Presentation size={18} />,    color: '#E8541E', bg: '#FFF0E8' },
  audio:        { icon: <Volume2 size={18} />,          color: '#00897B', bg: '#E0F2F1' },
};

const TYPE_LABELS = {
  article: 'Article',
  video: 'Vidéo',
  loi: 'Loi / Texte',
  guide: 'Guide pratique',
  infographie: 'Infographie',
  formation: 'Formation',
  audio: 'Audio',
};

export default function ResourcesPage() {
  const [resources, setResources] = useState([]);
  const [filter, setFilter] = useState('');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [selected, setSelected] = useState(null);

  useEffect(() => {
    setLoading(true);
    const params = { per_page: 12, page };
    if (filter) params.type = filter;
    if (search.trim()) params.search = search.trim();
    api.get('/resources', { params }).then(r => {
      setResources(r.data.data || r.data);
      if (r.data.last_page) setTotalPages(r.data.last_page);
    }).catch(() => {}).finally(() => setLoading(false));
  }, [filter, search, page]);

  useEffect(() => { setPage(1); }, [filter, search]);

  const categories = [...new Set(resources.map(r => r.category).filter(Boolean))];

  // ── Lecteur vocal (Text-to-Speech) ──
  function AudioPlayer({ text, title }) {
    const [playing, setPlaying] = useState(false);
    const [supported] = useState(() => 'speechSynthesis' in window);
    const utterRef = useRef(null);

    useEffect(() => {
      return () => { window.speechSynthesis?.cancel(); };
    }, []);

    const speak = (e) => {
      e.stopPropagation();
      if (!supported) return;
      if (playing) {
        window.speechSynthesis.cancel();
        setPlaying(false);
        return;
      }
      window.speechSynthesis.cancel();
      const toRead = title ? `${title}. ${text}` : text;
      const utter = new SpeechSynthesisUtterance(toRead);
      utter.lang = 'fr-FR';
      utter.rate = 0.9;
      utter.onend = () => setPlaying(false);
      utter.onerror = () => setPlaying(false);
      utterRef.current = utter;
      window.speechSynthesis.speak(utter);
      setPlaying(true);
    };

    if (!supported) return null;

    return (
      <div style={{
        background: 'var(--bg)', border: '1px solid var(--border)', borderRadius: 12,
        padding: '12px 16px', marginTop: 12
      }} onClick={e => e.stopPropagation()}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <button onClick={speak} style={{
            background: '#00897B', border: 'none', borderRadius: '50%', width: 36, height: 36,
            cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', flexShrink: 0
          }} aria-label={playing ? 'Arrêter la lecture' : 'Écouter le contenu'}>
            {playing ? <Pause size={16} /> : <Play size={16} style={{ marginLeft: 2 }} />}
          </button>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <Volume2 size={14} style={{ color: '#00897B', flexShrink: 0 }} />
              <span style={{ fontSize: 13, fontWeight: 600, color: playing ? '#00897B' : 'var(--text)' }}>
                {playing ? 'Lecture en cours…' : 'Écouter le contenu'}
              </span>
            </div>
            <span style={{ fontSize: 11, color: 'var(--text-light)', marginTop: 2, display: 'block' }}>
              Pour les personnes ne pouvant pas lire
            </span>
          </div>
          {playing && (
            <div style={{ display: 'flex', gap: 3 }}>
              {[0, 1, 2].map(i => (
                <div key={i} style={{
                  width: 3, height: 16, background: '#00897B', borderRadius: 2,
                  animation: `tts-bar 0.8s ease-in-out ${i * 0.15}s infinite alternate`
                }} />
              ))}
            </div>
          )}
        </div>
        <style>{`@keyframes tts-bar { from { transform: scaleY(0.3); } to { transform: scaleY(1); } }`}</style>
      </div>
    );
  }

  return (
    <div className="section">
      <div className="section-title">
        <h2>Ressources & Informations</h2>
        <p>Guides, articles, lois et formations pour vous informer et vous protéger</p>
      </div>

      {/* Search + Filters */}
      <div style={{
        display: 'flex', gap: 12, flexWrap: 'wrap', marginBottom: 20,
        background: 'var(--card-bg)', border: '1px solid var(--border)', borderRadius: 12, padding: 16
      }}>
        <div style={{ flex: '1 1 280px', position: 'relative' }}>
          <Search size={16} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-light)' }} />
          <input
            type="text"
            placeholder="Rechercher un titre, sujet, mot-clé..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            style={{
              width: '100%', padding: '10px 12px 10px 36px', border: '1px solid var(--border)',
              borderRadius: 8, fontSize: 14, background: 'var(--bg)'
            }}
          />
        </div>
        {(search || filter) && (
          <button onClick={() => { setSearch(''); setFilter(''); }}
            className="btn btn-outline" style={{ padding: '10px 14px', fontSize: 13 }}>
            <X size={14} /> Réinitialiser
          </button>
        )}
      </div>

      {/* Type tabs */}
      <div className="tabs">
        <button className={`tab ${filter === '' ? 'active' : ''}`} onClick={() => setFilter('')}>
          <BookOpen size={14} /> Tout
        </button>
        {Object.entries(TYPE_LABELS).map(([key, label]) => (
          <button key={key} className={`tab ${filter === key ? 'active' : ''}`} onClick={() => setFilter(key)}>
            {TYPE_ICONS[key]?.icon} {label}
          </button>
        ))}
      </div>

      {loading ? (
        <p style={{ textAlign: 'center', color: 'var(--text-light)', padding: 40 }}>Chargement...</p>
      ) : (
        <>
          <div className="grid-3">
            {resources.map(r => {
              const ti = TYPE_ICONS[r.type] || {};
              return (
                <div key={r.id} className="card" style={{ cursor: 'pointer', transition: 'transform .15s, box-shadow .15s', display: 'flex', flexDirection: 'column' }}
                  onClick={() => setSelected(r)}
                  onMouseEnter={e => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 8px 24px rgba(0,0,0,0.1)'; }}
                  onMouseLeave={e => { e.currentTarget.style.transform = ''; e.currentTarget.style.boxShadow = ''; }}
                >
                  {/* Type banner */}
                  <div style={{ background: ti.bg, borderRadius: '8px', padding: '10px 14px', marginBottom: 14, display: 'flex', alignItems: 'center', gap: 8 }}>
                    <IconBadge color={ti.color} bg="white" size="sm">{ti.icon}</IconBadge>
                    <span style={{ fontWeight: 600, fontSize: 12, color: ti.color }}>{TYPE_LABELS[r.type] || r.type}</span>
                    {r.tag && (
                      <span style={{ marginLeft: 'auto', background: 'white', padding: '2px 8px', borderRadius: 10, fontSize: 11, fontWeight: 600, color: 'var(--orange)' }}>
                        {r.tag}
                      </span>
                    )}
                  </div>

                  <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 8, lineHeight: 1.4 }}>{r.title}</h3>
                  <p style={{
                    fontSize: 13, color: 'var(--text-light)', marginBottom: 12, flex: 1, lineHeight: 1.5,
                    display: '-webkit-box', WebkitLineClamp: 3, WebkitBoxOrient: 'vertical', overflow: 'hidden'
                  }}>{r.description}</p>

                  {/* Lecteur vocal TTS sur toutes les ressources */}
                  <AudioPlayer text={r.description} title={r.title} />

                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 'auto', paddingTop: 12, borderTop: '1px solid var(--border)' }}>
                    {r.duration && (
                      <span style={{ fontSize: 12, color: 'var(--text-light)', display: 'flex', alignItems: 'center', gap: 4 }}>
                        <Clock size={12} /> {r.duration}
                      </span>
                    )}
                    {r.category && (
                      <span style={{ fontSize: 11, color: 'var(--text-light)', display: 'flex', alignItems: 'center', gap: 4 }}>
                        <Tag size={11} /> {r.category}
                      </span>
                    )}
                  </div>
                </div>
              );
            })}
            {resources.length === 0 && (
              <div style={{ gridColumn: '1 / -1', textAlign: 'center', padding: 40 }}>
                <Search size={40} style={{ color: 'var(--text-light)', marginBottom: 12 }} />
                <p style={{ color: 'var(--text-light)', fontSize: 15 }}>Aucune ressource trouvée</p>
                <button onClick={() => { setSearch(''); setFilter(''); }}
                  className="btn btn-outline" style={{ marginTop: 12 }}>Réinitialiser</button>
              </div>
            )}
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div style={{ display: 'flex', justifyContent: 'center', gap: 8, marginTop: 24 }}>
              <button disabled={page === 1} onClick={() => setPage(p => p - 1)}
                style={{ padding: '8px 12px', border: '1px solid var(--border)', borderRadius: 6, background: 'var(--card-bg)', cursor: page > 1 ? 'pointer' : 'default', opacity: page === 1 ? 0.4 : 1 }}>
                <ChevronLeft size={16} />
              </button>
              {Array.from({ length: totalPages }, (_, i) => (
                <button key={i + 1} onClick={() => setPage(i + 1)}
                  style={{
                    padding: '8px 14px', border: '1px solid var(--border)', borderRadius: 6,
                    background: page === i + 1 ? 'var(--purple)' : 'var(--card-bg)',
                    color: page === i + 1 ? 'white' : 'var(--text)', cursor: 'pointer', fontWeight: page === i + 1 ? 700 : 400, fontSize: 13
                  }}>{i + 1}</button>
              ))}
              <button disabled={page === totalPages} onClick={() => setPage(p => p + 1)}
                style={{ padding: '8px 12px', border: '1px solid var(--border)', borderRadius: 6, background: 'var(--card-bg)', cursor: page < totalPages ? 'pointer' : 'default', opacity: page === totalPages ? 0.4 : 1 }}>
                <ChevronRight size={16} />
              </button>
            </div>
          )}
        </>
      )}

      {/* Detail Modal */}
      {selected && (
        <div style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 1000,
          display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 20
        }} onClick={() => setSelected(null)}>
          <div style={{
            background: 'var(--card-bg)', borderRadius: 16, maxWidth: 600, width: '100%',
            maxHeight: '85vh', overflow: 'auto'
          }} onClick={e => e.stopPropagation()}>
            {/* Header */}
            <div style={{
              background: TYPE_ICONS[selected.type]?.bg || '#f5f5f5',
              padding: '24px', borderRadius: '16px 16px 0 0',
              display: 'flex', alignItems: 'flex-start', gap: 16
            }}>
              <IconBadge color={TYPE_ICONS[selected.type]?.color} bg="white" size="lg">
                {TYPE_ICONS[selected.type]?.icon}
              </IconBadge>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 8 }}>
                  <span className="badge" style={{ background: 'white', color: TYPE_ICONS[selected.type]?.color }}>
                    {TYPE_LABELS[selected.type]}
                  </span>
                  {selected.tag && <span className="badge badge-orange">{selected.tag}</span>}
                  {selected.category && <span className="badge" style={{ background: 'white', color: 'var(--text-light)' }}>{selected.category}</span>}
                </div>
                <h2 style={{ fontSize: 18, fontWeight: 800, lineHeight: 1.4 }}>{selected.title}</h2>
              </div>
              <button onClick={() => setSelected(null)}
                style={{ background: 'rgba(0,0,0,0.1)', border: 'none', borderRadius: '50%', width: 32, height: 32, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <X size={16} />
              </button>
            </div>

            {/* Body */}
            <div style={{ padding: 24 }}>
              {selected.duration && (
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 16, fontSize: 13, color: 'var(--text-light)' }}>
                  <Clock size={14} /> {selected.duration}
                </div>
              )}

              <div style={{ fontSize: 15, lineHeight: 1.8, color: 'var(--text)', whiteSpace: 'pre-wrap' }}>
                {selected.description}
              </div>

              {/* Lecteur vocal TTS dans le modal */}
              <div style={{ marginTop: 20 }}>
                <AudioPlayer text={selected.description} title={selected.title} />
              </div>

              {selected.url && (
                <a href={selected.url} target="_blank" rel="noopener noreferrer"
                  className="btn btn-primary"
                  style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, width: '100%', marginTop: 24, padding: '14px 0', fontSize: 15 }}>
                  <ExternalLink size={18} /> Accéder à la ressource
                </a>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
