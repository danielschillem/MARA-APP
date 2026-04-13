import { useState, useEffect, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import api from '../api';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, LineChart, Line, Legend, AreaChart, Area,
} from 'recharts';
import {
  Globe, Database, Calendar, TrendingUp, FileText, RefreshCw,
  Search, ChevronLeft, ChevronRight, ExternalLink, Filter, BarChart3,
  PieChart as PieChartIcon, Clock, BookOpen, Download,
} from 'lucide-react';
import IconBadge from '../components/IconBadge';

const COLORS = ['#7B2FBE', '#E8541E', '#27AE60', '#F39C12', '#E74C3C', '#3498DB', '#9B59B6', '#1ABC9C', '#E67E22', '#2ECC71', '#8E44AD', '#16A085'];

export default function ObservatoryPage() {
  const { t } = useTranslation();
  const [stats, setStats] = useState(null);
  const [reports, setReports] = useState(null);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [tab, setTab] = useState('dashboard');
  const [filters, setFilters] = useState({ search: '', source: '', year: '', format: '', page: 1 });

  useEffect(() => {
    api.get('/observatory/stats')
      .then(r => setStats(r.data))
      .catch(() => { })
      .finally(() => setLoading(false));
  }, []);

  const loadReports = useCallback(() => {
    const params = { per_page: 15, page: filters.page };
    if (filters.search) params.search = filters.search;
    if (filters.source) params.source = filters.source;
    if (filters.year) params.year = filters.year;
    if (filters.format) params.format = filters.format;
    api.get('/observatory/reliefweb')
      .then(r => setReports(r.data))
      .catch(() => { });
  }, [filters]);

  useEffect(() => {
    if (tab === 'reports') loadReports();
  }, [tab, loadReports]);

  const handleSync = async () => {
    setSyncing(true);
    try {
      await api.post('/observatory/reliefweb/sync');
      const r = await api.get('/observatory/stats');
      setStats(r.data);
    } catch { /* ignore */ }
    setSyncing(false);
  };

  if (loading) {
    return (
      <div className="section" style={{ textAlign: 'center', paddingTop: 100 }}>
        <RefreshCw size={32} className="spin" style={{ color: 'var(--purple)', marginBottom: 16 }} />
        <p style={{ color: 'var(--text-light)' }}>Chargement de l'observatoire...</p>
      </div>
    );
  }

  // Prepare chart data
  const sourceData = stats?.sources ? Object.entries(stats.sources).map(([name, value]) => ({ name: name.length > 25 ? name.slice(0, 22) + '...' : name, fullName: name, value })) : [];
  const themeData = stats?.themes ? Object.entries(stats.themes).map(([name, value]) => ({ name: name.length > 30 ? name.slice(0, 27) + '...' : name, fullName: name, value })) : [];
  const yearData = stats?.by_year ? Object.entries(stats.by_year).map(([year, value]) => ({ year, value })) : [];
  const monthData = stats?.by_month ? Object.entries(stats.by_month).map(([month, value]) => ({ month, value })) : [];
  const formatData = stats?.by_format ? Object.entries(stats.by_format).map(([name, value]) => ({ name, value })) : [];

  const sourceOptions = stats?.sources ? Object.keys(stats.sources) : [];
  const yearOptions = stats?.by_year ? Object.keys(stats.by_year).reverse() : [];

  const tabs = [
    { key: 'dashboard', label: 'Tableau de bord', icon: BarChart3 },
    { key: 'trends', label: 'Tendances', icon: TrendingUp },
    { key: 'reports', label: 'Rapports', icon: FileText },
  ];

  return (
    <div className="section">
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24, flexWrap: 'wrap', gap: 16 }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 4 }}>
            <IconBadge color="#7B2FBE" bg="#EDE0FA" size="md"><Globe size={22} /></IconBadge>
            <h2 style={{ fontSize: 24, fontWeight: 800, margin: 0 }}>Observatoire Statistique</h2>
          </div>
          <p style={{ color: 'var(--text-light)', fontSize: 14, margin: 0 }}>
            Données issues de <strong>ReliefWeb (OCHA/ONU)</strong> — Protection & Violences basées sur le genre au Burkina Faso
          </p>
        </div>
        <button className="btn btn-outline btn-sm" onClick={handleSync} disabled={syncing} style={{ fontSize: 13 }}>
          <RefreshCw size={14} className={syncing ? 'spin' : ''} style={{ marginRight: 6 }} />
          {syncing ? 'Synchronisation...' : 'Actualiser les données'}
        </button>
      </div>

      {/* Source attribution */}
      <div style={{
        background: 'linear-gradient(135deg, #EDE0FA 0%, #FFF0E8 100%)',
        borderRadius: 12, padding: '14px 20px', marginBottom: 24,
        display: 'flex', alignItems: 'center', gap: 12, fontSize: 13, color: '#5a3d7a',
      }}>
        <Database size={18} />
        <div>
          <strong>Source :</strong> ReliefWeb API (api.reliefweb.int) — Données ouvertes sous licence{' '}
          <a href="https://creativecommons.org/licenses/by/4.0/" target="_blank" rel="noopener noreferrer" style={{ color: '#7B2FBE', textDecoration: 'underline' }}>
            Creative Commons BY 4.0
          </a>
          {stats?.last_sync && (
            <span style={{ marginLeft: 12, opacity: 0.7 }}>
              <Clock size={12} style={{ verticalAlign: -1 }} /> Dernière sync : {new Date(stats.last_sync).toLocaleDateString('fr-FR')}
            </span>
          )}
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 24, borderBottom: '2px solid var(--border)', paddingBottom: 0, overflowX: 'auto' }}>
        {tabs.map(tb => {
          const Icon = tb.icon;
          return (
            <button key={tb.key} onClick={() => setTab(tb.key)} className="nav-link" style={{
              fontSize: 13, padding: '10px 16px', borderRadius: '8px 8px 0 0',
              borderBottom: tab === tb.key ? '2px solid var(--purple)' : '2px solid transparent',
              color: tab === tb.key ? 'var(--purple)' : 'var(--text-light)',
              fontWeight: tab === tb.key ? 600 : 400,
              background: tab === tb.key ? 'var(--purple-xlight)' : 'transparent',
              display: 'flex', alignItems: 'center', gap: 6, whiteSpace: 'nowrap',
            }}>
              <Icon size={14} /> {tb.label}
            </button>
          );
        })}
      </div>

      {/* ── TAB: DASHBOARD ── */}
      {tab === 'dashboard' && (
        <>
          {/* KPI cards */}
          <div className="grid-4" style={{ marginBottom: 32 }}>
            {[
              { icon: <FileText size={22} />, num: stats?.total || 0, label: 'Rapports collectés', sub: 'depuis ReliefWeb', color: '#7B2FBE', bg: '#EDE0FA' },
              { icon: <Globe size={22} />, num: sourceData.length, label: 'Sources actives', sub: 'organisations', color: '#E8541E', bg: '#FFF0E8' },
              { icon: <BookOpen size={22} />, num: themeData.length, label: 'Thématiques', sub: 'couvertes', color: '#27AE60', bg: '#E8F5E9' },
              { icon: <Calendar size={22} />, num: stats?.date_range ? `${new Date(stats.date_range.min).getFullYear()}-${new Date(stats.date_range.max).getFullYear()}` : '—', label: 'Période couverte', sub: 'plage temporelle', color: '#3498DB', bg: '#E3F2FD' },
            ].map((s, i) => (
              <div key={i} className="stat-card">
                <IconBadge color={s.color} bg={s.bg} size="md" style={{ marginBottom: 8 }}>{s.icon}</IconBadge>
                <div className="stat-number" style={{ color: s.color }}>{s.num}</div>
                <div className="stat-label">{s.label}</div>
                <div style={{ fontSize: 12, color: 'var(--text-light)' }}>{s.sub}</div>
              </div>
            ))}
          </div>

          {/* Charts row 1 */}
          <div className="grid-2" style={{ marginBottom: 32 }}>
            {/* By year */}
            <div className="card" style={{ padding: 20 }}>
              <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
                <BarChart3 size={16} color="var(--purple)" /> Rapports par année
              </h3>
              <ResponsiveContainer width="100%" height={280}>
                <BarChart data={yearData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                  <XAxis dataKey="year" tick={{ fontSize: 11 }} />
                  <YAxis tick={{ fontSize: 11 }} />
                  <Tooltip contentStyle={{ borderRadius: 8, fontSize: 13 }} />
                  <Bar dataKey="value" name="Rapports" fill="#7B2FBE" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>

            {/* By theme (pie) */}
            <div className="card" style={{ padding: 20 }}>
              <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
                <PieChartIcon size={16} color="#E8541E" /> Distribution par thématique
              </h3>
              <ResponsiveContainer width="100%" height={280}>
                <PieChart>
                  <Pie data={themeData.slice(0, 8)} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={90} innerRadius={40} label={({ name, percent }) => `${name} (${(percent * 100).toFixed(0)}%)`} labelLine={false}>
                    {themeData.slice(0, 8).map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                  </Pie>
                  <Tooltip formatter={(v, n, p) => [v, p.payload.fullName || n]} contentStyle={{ borderRadius: 8, fontSize: 13 }} />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Top sources bar */}
          <div className="card" style={{ padding: 20, marginBottom: 32 }}>
            <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
              <Database size={16} color="#27AE60" /> Top sources de données
            </h3>
            <ResponsiveContainer width="100%" height={Math.max(200, sourceData.length * 32)}>
              <BarChart data={sourceData.slice(0, 12)} layout="vertical" margin={{ left: 120 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                <XAxis type="number" tick={{ fontSize: 11 }} />
                <YAxis type="category" dataKey="name" tick={{ fontSize: 11 }} width={120} />
                <Tooltip formatter={(v, n, p) => [v, p.payload.fullName || n]} contentStyle={{ borderRadius: 8, fontSize: 13 }} />
                <Bar dataKey="value" name="Rapports" fill="#E8541E" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* Recent reports */}
          <div className="card" style={{ padding: 20 }}>
            <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
              <Clock size={16} color="#3498DB" /> Rapports récents
            </h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {(stats?.recent || []).map(r => (
                <div key={r.id} style={{
                  display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start',
                  padding: '12px 16px', borderRadius: 10, background: 'var(--bg)',
                  border: '1px solid var(--border)', gap: 12,
                }}>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4, lineHeight: 1.3 }}>{r.title}</div>
                    <div style={{ fontSize: 12, color: 'var(--text-light)', display: 'flex', gap: 10, flexWrap: 'wrap' }}>
                      {r.source && <span className="badge badge-purple" style={{ fontSize: 11 }}>{r.source}</span>}
                      {r.format && <span className="badge badge-orange" style={{ fontSize: 11 }}>{r.format}</span>}
                      {r.published_at && <span><Calendar size={11} style={{ verticalAlign: -1 }} /> {new Date(r.published_at).toLocaleDateString('fr-FR')}</span>}
                    </div>
                  </div>
                  {r.url && (
                    <a href={r.url} target="_blank" rel="noopener noreferrer" className="btn btn-outline btn-sm" style={{ fontSize: 11, whiteSpace: 'nowrap', flexShrink: 0 }}>
                      <ExternalLink size={12} /> Lire
                    </a>
                  )}
                </div>
              ))}
            </div>
          </div>
        </>
      )}

      {/* ── TAB: TRENDS ── */}
      {tab === 'trends' && (
        <>
          {/* Monthly trend (last 24 months) */}
          <div className="card" style={{ padding: 20, marginBottom: 32 }}>
            <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
              <TrendingUp size={16} color="#7B2FBE" /> Évolution mensuelle (24 derniers mois)
            </h3>
            <ResponsiveContainer width="100%" height={320}>
              <AreaChart data={monthData}>
                <defs>
                  <linearGradient id="colorRw" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#7B2FBE" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#7B2FBE" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                <XAxis dataKey="month" tick={{ fontSize: 10 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip contentStyle={{ borderRadius: 8, fontSize: 13 }} />
                <Area type="monotone" dataKey="value" name="Rapports" stroke="#7B2FBE" fillOpacity={1} fill="url(#colorRw)" strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>

          {/* Year-over-year */}
          <div className="card" style={{ padding: 20, marginBottom: 32 }}>
            <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
              <BarChart3 size={16} color="#E8541E" /> Volume annuel de publications
            </h3>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={yearData}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
                <XAxis dataKey="year" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip contentStyle={{ borderRadius: 8, fontSize: 13 }} />
                <Legend />
                <Line type="monotone" dataKey="value" name="Rapports" stroke="#E8541E" strokeWidth={2} dot={{ r: 4, fill: '#E8541E' }} />
              </LineChart>
            </ResponsiveContainer>
          </div>

          {/* Format distribution */}
          <div className="grid-2">
            <div className="card" style={{ padding: 20 }}>
              <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
                <BookOpen size={16} color="#27AE60" /> Types de documents
              </h3>
              <ResponsiveContainer width="100%" height={250}>
                <PieChart>
                  <Pie data={formatData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label={({ name, percent }) => `${name} (${(percent * 100).toFixed(0)}%)`}>
                    {formatData.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                  </Pie>
                  <Tooltip contentStyle={{ borderRadius: 8, fontSize: 13 }} />
                </PieChart>
              </ResponsiveContainer>
            </div>

            <div className="card" style={{ padding: 20 }}>
              <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
                <Filter size={16} color="#F39C12" /> Thématiques détaillées
              </h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6, maxHeight: 250, overflow: 'auto' }}>
                {themeData.map((th, i) => (
                  <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <div style={{
                      width: 10, height: 10, borderRadius: '50%',
                      background: COLORS[i % COLORS.length], flexShrink: 0,
                    }} />
                    <div style={{ flex: 1, fontSize: 13, minWidth: 0 }}>
                      <span title={th.fullName}>{th.fullName}</span>
                    </div>
                    <span style={{ fontWeight: 700, fontSize: 13, color: 'var(--purple)' }}>{th.value}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </>
      )}

      {/* ── TAB: REPORTS ── */}
      {tab === 'reports' && (
        <>
          {/* Filters */}
          <div className="card" style={{ padding: 16, marginBottom: 20 }}>
            <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center' }}>
              <div style={{ flex: '1 1 200px', position: 'relative' }}>
                <Search size={14} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-light)' }} />
                <input
                  className="form-input"
                  placeholder="Rechercher un rapport..."
                  value={filters.search}
                  onChange={e => setFilters(f => ({ ...f, search: e.target.value, page: 1 }))}
                  style={{ paddingLeft: 34, fontSize: 13 }}
                />
              </div>
              <select className="form-select" value={filters.source} onChange={e => setFilters(f => ({ ...f, source: e.target.value, page: 1 }))} style={{ fontSize: 13, minWidth: 160 }}>
                <option value="">Toutes les sources</option>
                {sourceOptions.map(s => <option key={s} value={s}>{s}</option>)}
              </select>
              <select className="form-select" value={filters.year} onChange={e => setFilters(f => ({ ...f, year: e.target.value, page: 1 }))} style={{ fontSize: 13, minWidth: 100 }}>
                <option value="">Toutes les années</option>
                {yearOptions.map(y => <option key={y} value={y}>{y}</option>)}
              </select>
            </div>
          </div>

          {/* Report list */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 20 }}>
            {reports?.data?.length === 0 && (
              <div className="card" style={{ padding: 40, textAlign: 'center', color: 'var(--text-light)' }}>
                Aucun rapport trouvé avec ces filtres.
              </div>
            )}
            {(reports?.data || []).map(r => (
              <div key={r.id} className="card" style={{
                padding: '16px 20px', display: 'flex', justifyContent: 'space-between',
                alignItems: 'flex-start', gap: 12,
              }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 6, lineHeight: 1.3 }}>{r.title}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-light)', display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
                    {r.source && <span className="badge badge-purple" style={{ fontSize: 11 }}>{r.source}</span>}
                    {r.format && <span className="badge badge-orange" style={{ fontSize: 11 }}>{r.format}</span>}
                    {r.theme && <span className="badge badge-success" style={{ fontSize: 11 }}>{r.theme.length > 50 ? r.theme.slice(0, 47) + '...' : r.theme}</span>}
                    {r.published_at && <span><Calendar size={11} style={{ verticalAlign: -1 }} /> {new Date(r.published_at).toLocaleDateString('fr-FR')}</span>}
                  </div>
                </div>
                {r.url && (
                  <a href={r.url} target="_blank" rel="noopener noreferrer" className="btn btn-outline btn-sm" style={{ fontSize: 11, whiteSpace: 'nowrap', flexShrink: 0 }}>
                    <ExternalLink size={12} /> Lire sur ReliefWeb
                  </a>
                )}
              </div>
            ))}
          </div>

          {/* Pagination */}
          {reports && reports.last_page > 1 && (
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 12 }}>
              <button
                className="btn btn-outline btn-sm"
                disabled={reports.current_page <= 1}
                onClick={() => setFilters(f => ({ ...f, page: f.page - 1 }))}
              >
                <ChevronLeft size={14} />
              </button>
              <span style={{ fontSize: 13, color: 'var(--text-light)' }}>
                Page {reports.current_page} / {reports.last_page} ({reports.total} résultats)
              </span>
              <button
                className="btn btn-outline btn-sm"
                disabled={reports.current_page >= reports.last_page}
                onClick={() => setFilters(f => ({ ...f, page: f.page + 1 }))}
              >
                <ChevronRight size={14} />
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
