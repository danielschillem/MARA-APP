import { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate, Link } from 'react-router-dom';
import api from '../api';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, LineChart, Line, Legend } from 'recharts';
import { AlertTriangle, FileText, MessageCircle, Users, Clock, TrendingUp, Shield, CheckCircle, ArrowRight } from 'lucide-react';
import IconBadge from '../components/IconBadge';

const COLORS = ['#7B2FBE', '#E8541E', '#27AE60', '#F39C12', '#E74C3C', '#3498DB', '#9B59B6', '#1ABC9C'];

const STATUS_LABELS = { nouveau: 'Nouveau', en_cours: 'En cours', resolu: 'Résolu', urgent: 'Urgent', cloture: 'Clôturé' };
const STATUS_BADGE = { nouveau: 'badge-purple', en_cours: 'badge-warning', resolu: 'badge-success', urgent: 'badge-danger', cloture: 'badge-orange' };
const PRIORITY_BADGE = { basse: 'badge-success', moyenne: 'badge-purple', haute: 'badge-warning', critique: 'badge-danger' };

export default function DashboardPage() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState('overview');

  useEffect(() => {
    if (!user) { navigate('/login'); return; }
    api.get('/dashboard').then(r => setStats(r.data)).catch(() => {}).finally(() => setLoading(false));
  }, [user, navigate]);

  if (!user) return null;
  if (loading) return <div className="section" style={{ textAlign: 'center', paddingTop: 100 }}>Chargement...</div>;

  const statusData = stats?.reports_by_status ? Object.entries(stats.reports_by_status).map(([name, value]) => ({ name: STATUS_LABELS[name] || name, value })) : [];
  const regionData = stats?.reports_by_region ? Object.entries(stats.reports_by_region).map(([name, value]) => ({ name, value })) : [];
  const priorityData = stats?.reports_by_priority ? Object.entries(stats.reports_by_priority).map(([name, value]) => ({ name, value })) : [];
  const monthData = stats?.reports_by_month ? Object.entries(stats.reports_by_month).map(([month, value]) => ({ month, value })) : [];
  const violenceData = stats?.reports_by_violence_type ? Object.entries(stats.reports_by_violence_type).map(([name, value]) => ({ name, value })).sort((a, b) => b.value - a.value) : [];

  const tabs = [
    { key: 'overview', label: 'Vue d\'ensemble' },
    { key: 'analytics', label: 'Analytiques' },
    { key: 'reports', label: 'Signalements' },
  ];
  if (stats?.my_assigned) tabs.push({ key: 'assigned', label: 'Mes dossiers' });

  return (
    <div className="section">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 24, fontWeight: 800 }}>Tableau de bord</h2>
          <p style={{ color: 'var(--text-light)', fontSize: 14 }}>Bienvenue, {user.name}</p>
        </div>
        <Link to="/signalements" className="btn btn-primary" style={{ fontSize: 13 }}>
          <FileText size={16} style={{ marginRight: 6 }} /> Gérer les signalements
        </Link>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 24, borderBottom: '2px solid var(--border)', paddingBottom: 0 }}>
        {tabs.map(t => (
          <button key={t.key} onClick={() => setTab(t.key)} className="nav-link" style={{
            fontSize: 13, padding: '10px 16px', borderRadius: '8px 8px 0 0',
            borderBottom: tab === t.key ? '2px solid var(--purple)' : '2px solid transparent',
            color: tab === t.key ? 'var(--purple)' : 'var(--text-light)',
            fontWeight: tab === t.key ? 600 : 400, background: tab === t.key ? 'var(--purple-xlight)' : 'transparent',
          }}>{t.label}</button>
        ))}
      </div>

      {/* ── TAB: OVERVIEW ── */}
      {tab === 'overview' && (
        <>
          {/* Stat cards */}
          <div className="grid-4" style={{ marginBottom: 32 }}>
            {[
              { icon: <FileText size={22} />, num: stats?.reports_total || 0, label: 'Signalements', sub: `${stats?.reports_new || 0} nouveaux`, color: '#7B2FBE', bg: '#EDE0FA' },
              { icon: <AlertTriangle size={22} />, num: stats?.reports_urgent || 0, label: 'Urgents', sub: 'priorité critique', color: '#E74C3C', bg: '#FFEBEE' },
              { icon: <MessageCircle size={22} />, num: stats?.conversations_active || 0, label: 'Chats actifs', sub: `${stats?.conversations_waiting || 0} en attente`, color: '#27AE60', bg: '#E8F5E9' },
              { icon: <Users size={22} />, num: stats?.professionals_online || 0, label: 'Pros en ligne', sub: 'conseillers & pros', color: '#E8541E', bg: '#FFF0E8' },
            ].map((s, i) => (
              <div key={i} className="stat-card">
                <IconBadge color={s.color} bg={s.bg} size="md" style={{ marginBottom: 8 }}>{s.icon}</IconBadge>
                <div className="stat-number" style={{ color: s.color }}>{s.num}</div>
                <div className="stat-label">{s.label}</div>
                <div style={{ fontSize: 11, color: 'var(--text-light)', marginTop: 4 }}>{s.sub}</div>
              </div>
            ))}
          </div>

          {/* Quick charts */}
          <div className="grid-2" style={{ marginBottom: 32 }}>
            <div className="card">
              <h3 style={{ fontSize: 16, fontWeight: 700, marginBottom: 16 }}>Répartition par statut</h3>
              {statusData.length > 0 ? (
                <ResponsiveContainer width="100%" height={250}>
                  <PieChart>
                    <Pie data={statusData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label={({ name, value }) => `${name}: ${value}`}>
                      {statusData.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              ) : <p style={{ color: 'var(--text-light)', textAlign: 'center', padding: 40 }}>Aucune donnée</p>}
            </div>
            <div className="card">
              <h3 style={{ fontSize: 16, fontWeight: 700, marginBottom: 16 }}>Par région</h3>
              {regionData.length > 0 ? (
                <ResponsiveContainer width="100%" height={250}>
                  <BarChart data={regionData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" tick={{ fontSize: 10 }} />
                    <YAxis allowDecimals={false} />
                    <Tooltip />
                    <Bar dataKey="value" fill="var(--purple)" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              ) : <p style={{ color: 'var(--text-light)', textAlign: 'center', padding: 40 }}>Aucune donnée</p>}
            </div>
          </div>

          {/* Recent reports */}
          <div className="card" style={{ padding: 0, overflow: 'auto' }}>
            <div style={{ padding: '16px 16px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: 16, fontWeight: 700 }}>Derniers signalements</h3>
              <Link to="/signalements" style={{ fontSize: 13, color: 'var(--purple)', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 4 }}>
                Voir tout <ArrowRight size={14} />
              </Link>
            </div>
            <table className="data-table" style={{ marginTop: 12 }}>
              <thead>
                <tr><th>Référence</th><th>Date</th><th>Région</th><th>Statut</th><th>Priorité</th></tr>
              </thead>
              <tbody>
                {(!stats?.recent_reports || stats.recent_reports.length === 0) ? (
                  <tr><td colSpan={5} style={{ textAlign: 'center', color: 'var(--text-light)' }}>Aucun signalement</td></tr>
                ) : stats.recent_reports.map(r => (
                  <tr key={r.id}>
                    <td style={{ fontWeight: 600, color: 'var(--purple)' }}>{r.reference}</td>
                    <td>{new Date(r.created_at).toLocaleDateString('fr-FR')}</td>
                    <td>{r.region || '-'}</td>
                    <td><span className={`badge ${STATUS_BADGE[r.status] || ''}`}>{STATUS_LABELS[r.status] || r.status}</span></td>
                    <td><span className={`badge ${PRIORITY_BADGE[r.priority] || ''}`}>{r.priority}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}

      {/* ── TAB: ANALYTICS ── */}
      {tab === 'analytics' && (
        <>
          {/* Trend line */}
          <div className="card" style={{ marginBottom: 32 }}>
            <h3 style={{ fontSize: 16, fontWeight: 700, marginBottom: 16 }}>
              <TrendingUp size={18} style={{ verticalAlign: 'middle', marginRight: 8 }} />Évolution mensuelle
            </h3>
            {monthData.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={monthData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="month" tick={{ fontSize: 11 }} />
                  <YAxis allowDecimals={false} />
                  <Tooltip />
                  <Line type="monotone" dataKey="value" stroke="var(--purple)" strokeWidth={3} dot={{ r: 5, fill: 'var(--purple)' }} name="Signalements" />
                </LineChart>
              </ResponsiveContainer>
            ) : <p style={{ color: 'var(--text-light)', textAlign: 'center', padding: 40 }}>Pas encore de données mensuelles</p>}
          </div>

          <div className="grid-2" style={{ marginBottom: 32 }}>
            {/* By violence type */}
            <div className="card">
              <h3 style={{ fontSize: 16, fontWeight: 700, marginBottom: 16 }}>Par type de violence</h3>
              {violenceData.length > 0 ? (
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={violenceData} layout="vertical">
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis type="number" allowDecimals={false} />
                    <YAxis type="category" dataKey="name" tick={{ fontSize: 11 }} width={140} />
                    <Tooltip />
                    <Bar dataKey="value" fill="var(--orange)" radius={[0, 4, 4, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              ) : <p style={{ color: 'var(--text-light)', textAlign: 'center', padding: 40 }}>Aucune donnée</p>}
            </div>

            {/* By priority */}
            <div className="card">
              <h3 style={{ fontSize: 16, fontWeight: 700, marginBottom: 16 }}>Par priorité</h3>
              {priorityData.length > 0 ? (
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie data={priorityData} dataKey="value" nameKey="name" cx="50%" cy="50%" innerRadius={50} outerRadius={90} label={({ name, value }) => `${name}: ${value}`}>
                      {priorityData.map((_, i) => <Cell key={i} fill={['#27AE60', '#7B2FBE', '#F39C12', '#E74C3C'][i] || COLORS[i]} />)}
                    </Pie>
                    <Tooltip />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              ) : <p style={{ color: 'var(--text-light)', textAlign: 'center', padding: 40 }}>Aucune donnée</p>}
            </div>
          </div>

          {/* Summary cards */}
          <div className="grid-3">
            <div className="card" style={{ textAlign: 'center' }}>
              <Shield size={32} color="var(--purple)" />
              <h4 style={{ marginTop: 12, fontSize: 28, fontWeight: 800, color: 'var(--purple)' }}>{stats?.reports_resolved || 0}</h4>
              <p style={{ color: 'var(--text-light)', fontSize: 13 }}>Cas résolus</p>
              {stats?.reports_total > 0 && (
                <p style={{ fontSize: 12, color: 'var(--success)', fontWeight: 600, marginTop: 4 }}>
                  {Math.round((stats.reports_resolved / stats.reports_total) * 100)}% taux de résolution
                </p>
              )}
            </div>
            <div className="card" style={{ textAlign: 'center' }}>
              <Clock size={32} color="var(--warning)" />
              <h4 style={{ marginTop: 12, fontSize: 28, fontWeight: 800, color: 'var(--warning)' }}>{stats?.conversations_waiting || 0}</h4>
              <p style={{ color: 'var(--text-light)', fontSize: 13 }}>Chats en attente</p>
            </div>
            <div className="card" style={{ textAlign: 'center' }}>
              <CheckCircle size={32} color="var(--success)" />
              <h4 style={{ marginTop: 12, fontSize: 28, fontWeight: 800, color: 'var(--success)' }}>{stats?.resources_count || 0}</h4>
              <p style={{ color: 'var(--text-light)', fontSize: 13 }}>Ressources publiées</p>
            </div>
          </div>
        </>
      )}

      {/* ── TAB: REPORTS ── */}
      {tab === 'reports' && <ReportsTab />}

      {/* ── TAB: MY ASSIGNED ── */}
      {tab === 'assigned' && stats?.my_assigned && (
        <div className="card" style={{ padding: 0, overflow: 'auto' }}>
          <h3 style={{ padding: '16px 16px 0', fontSize: 16, fontWeight: 700 }}>Mes dossiers en cours</h3>
          <table className="data-table" style={{ marginTop: 12 }}>
            <thead>
              <tr><th>Référence</th><th>Date</th><th>Région</th><th>Statut</th><th>Priorité</th><th>Action</th></tr>
            </thead>
            <tbody>
              {stats.my_assigned.length === 0 ? (
                <tr><td colSpan={6} style={{ textAlign: 'center', color: 'var(--text-light)' }}>Aucun dossier assigné</td></tr>
              ) : stats.my_assigned.map(r => (
                <tr key={r.id}>
                  <td style={{ fontWeight: 600, color: 'var(--purple)' }}>{r.reference}</td>
                  <td>{new Date(r.created_at).toLocaleDateString('fr-FR')}</td>
                  <td>{r.region || '-'}</td>
                  <td><span className={`badge ${STATUS_BADGE[r.status] || ''}`}>{STATUS_LABELS[r.status] || r.status}</span></td>
                  <td><span className={`badge ${PRIORITY_BADGE[r.priority] || ''}`}>{r.priority}</span></td>
                  <td><Link to={`/signalements?ref=${r.reference}`} style={{ color: 'var(--purple)', fontWeight: 600, fontSize: 13 }}>Voir</Link></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

/* ─── REPORTS TAB (mini version in dashboard) ─── */
function ReportsTab() {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({ status: '', priority: '', search: '' });
  const [page, setPage] = useState(1);
  const [meta, setMeta] = useState({});

  const fetchReports = (p = 1) => {
    setLoading(true);
    const params = new URLSearchParams();
    params.set('page', p);
    if (filters.status) params.set('status', filters.status);
    if (filters.priority) params.set('priority', filters.priority);
    if (filters.search) params.set('search', filters.search);
    api.get(`/reports?${params}`).then(r => {
      setReports(r.data.data || []);
      setMeta({ last_page: r.data.last_page, current_page: r.data.current_page, total: r.data.total });
      setPage(p);
    }).catch(() => {}).finally(() => setLoading(false));
  };

  useEffect(() => { fetchReports(); }, []);

  const applyFilters = () => fetchReports(1);

  return (
    <>
      {/* Filters */}
      <div className="card" style={{ marginBottom: 16, display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'flex-end' }}>
        <div>
          <label style={{ fontSize: 12, fontWeight: 600, display: 'block', marginBottom: 4 }}>Recherche</label>
          <input type="text" placeholder="Référence, description..." value={filters.search} onChange={e => setFilters(f => ({ ...f, search: e.target.value }))}
            style={{ padding: '8px 12px', border: '2px solid var(--border)', borderRadius: 8, fontSize: 13, width: 200 }} onKeyDown={e => e.key === 'Enter' && applyFilters()} />
        </div>
        <div>
          <label style={{ fontSize: 12, fontWeight: 600, display: 'block', marginBottom: 4 }}>Statut</label>
          <select value={filters.status} onChange={e => setFilters(f => ({ ...f, status: e.target.value }))}
            style={{ padding: '8px 12px', border: '2px solid var(--border)', borderRadius: 8, fontSize: 13 }}>
            <option value="">Tous</option>
            {Object.entries(STATUS_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
          </select>
        </div>
        <div>
          <label style={{ fontSize: 12, fontWeight: 600, display: 'block', marginBottom: 4 }}>Priorité</label>
          <select value={filters.priority} onChange={e => setFilters(f => ({ ...f, priority: e.target.value }))}
            style={{ padding: '8px 12px', border: '2px solid var(--border)', borderRadius: 8, fontSize: 13 }}>
            <option value="">Toutes</option>
            <option value="basse">Basse</option>
            <option value="moyenne">Moyenne</option>
            <option value="haute">Haute</option>
            <option value="critique">Critique</option>
          </select>
        </div>
        <button className="btn btn-primary" onClick={applyFilters} style={{ fontSize: 13, padding: '8px 16px' }}>Filtrer</button>
      </div>

      {/* Table */}
      <div className="card" style={{ padding: 0, overflow: 'auto' }}>
        <div style={{ padding: '12px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--border)' }}>
          <span style={{ fontSize: 13, color: 'var(--text-light)' }}>{meta.total || 0} signalements</span>
          <Link to="/signalements" className="btn btn-outline" style={{ fontSize: 12, padding: '6px 14px' }}>Vue complète</Link>
        </div>
        {loading ? <p style={{ padding: 24, textAlign: 'center', color: 'var(--text-light)' }}>Chargement...</p> : (
          <table className="data-table">
            <thead>
              <tr><th>Référence</th><th>Date</th><th>Région</th><th>Types</th><th>Statut</th><th>Priorité</th><th>Assigné à</th></tr>
            </thead>
            <tbody>
              {reports.length === 0 ? (
                <tr><td colSpan={7} style={{ textAlign: 'center', color: 'var(--text-light)' }}>Aucun signalement</td></tr>
              ) : reports.map(r => (
                <tr key={r.id}>
                  <td style={{ fontWeight: 600, color: 'var(--purple)' }}>{r.reference}</td>
                  <td style={{ fontSize: 12 }}>{new Date(r.created_at).toLocaleDateString('fr-FR')}</td>
                  <td>{r.region || '-'}</td>
                  <td style={{ fontSize: 12 }}>{(r.violence_types || []).map(v => v.label_fr).join(', ') || '-'}</td>
                  <td><span className={`badge ${STATUS_BADGE[r.status] || ''}`}>{STATUS_LABELS[r.status] || r.status}</span></td>
                  <td><span className={`badge ${PRIORITY_BADGE[r.priority] || ''}`}>{r.priority}</span></td>
                  <td style={{ fontSize: 12 }}>{r.assigned_to_user?.name || <span style={{ color: 'var(--text-light)' }}>—</span>}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        {/* Pagination */}
        {meta.last_page > 1 && (
          <div style={{ padding: 12, display: 'flex', justifyContent: 'center', gap: 4 }}>
            {Array.from({ length: meta.last_page }, (_, i) => (
              <button key={i} onClick={() => fetchReports(i + 1)} className="nav-link" style={{
                fontSize: 12, padding: '4px 10px', minWidth: 32,
                background: page === i + 1 ? 'var(--purple)' : 'transparent',
                color: page === i + 1 ? 'white' : 'var(--text-light)',
                borderRadius: 6
              }}>{i + 1}</button>
            ))}
          </div>
        )}
      </div>
    </>
  );
}
