import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate, useSearchParams } from 'react-router-dom';
import api from '../api';
import { FileText, Search, Filter, X, ChevronLeft, ChevronRight, Edit3, UserPlus, Save, AlertTriangle, MapPin, Calendar, Clock, User, Shield, Download } from 'lucide-react';

const STATUS_LABELS = { nouveau: 'Nouveau', en_cours: 'En cours', resolu: 'Résolu', urgent: 'Urgent', cloture: 'Clôturé' };
const STATUS_BADGE = { nouveau: 'badge-purple', en_cours: 'badge-warning', resolu: 'badge-success', urgent: 'badge-danger', cloture: 'badge-orange' };
const PRIORITY_LABELS = { basse: 'Basse', moyenne: 'Moyenne', haute: 'Haute', critique: 'Critique' };
const PRIORITY_BADGE = { basse: 'badge-success', moyenne: 'badge-purple', haute: 'badge-warning', critique: 'badge-danger' };

export default function ReportManagementPage() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [meta, setMeta] = useState({});
  const [filters, setFilters] = useState({ search: searchParams.get('ref') || '', status: '', priority: '', assigned_to: '' });
  const [selectedReport, setSelectedReport] = useState(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [users, setUsers] = useState([]);
  const [editMode, setEditMode] = useState(false);
  const [editData, setEditData] = useState({});
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!user) navigate('/login');
  }, [user, navigate]);

  // Load users for assignment dropdown
  useEffect(() => {
    api.get('/me').then(() => {
      // We'll use a simple approach — fetch users from reports' assigned_to
    }).catch(() => { });
  }, []);

  const fetchReports = useCallback((p = 1) => {
    setLoading(true);
    const params = new URLSearchParams();
    params.set('page', p);
    params.set('per_page', 20);
    if (filters.search) params.set('search', filters.search);
    if (filters.status) params.set('status', filters.status);
    if (filters.priority) params.set('priority', filters.priority);
    if (filters.assigned_to) params.set('assigned_to', filters.assigned_to);
    api.get(`/reports?${params}`).then(r => {
      setReports(r.data.data || []);
      setMeta({ last_page: r.data.last_page, current_page: r.data.current_page, total: r.data.total });
      setPage(p);
    }).catch(() => { }).finally(() => setLoading(false));
  }, [filters]);

  useEffect(() => { fetchReports(); }, [fetchReports]);

  const openDetail = async (report) => {
    setDetailLoading(true);
    setSelectedReport(report);
    try {
      const { data } = await api.get(`/reports/${report.id}`);
      setSelectedReport(data);
      setEditData({ status: data.status, priority: data.priority, assigned_to: data.assigned_to || '', notes: data.notes || '' });
    } catch { /* silent */ }
    setDetailLoading(false);
  };

  const saveChanges = async () => {
    if (!selectedReport) return;
    setSaving(true);
    try {
      const payload = {};
      if (editData.status !== selectedReport.status) payload.status = editData.status;
      if (editData.priority !== selectedReport.priority) payload.priority = editData.priority;
      if (editData.assigned_to !== (selectedReport.assigned_to || '')) payload.assigned_to = editData.assigned_to || null;
      if (editData.notes !== (selectedReport.notes || '')) payload.notes = editData.notes;

      if (Object.keys(payload).length > 0) {
        const { data } = await api.put(`/reports/${selectedReport.id}`, payload);
        setSelectedReport(prev => ({ ...prev, ...data }));
        // Update in list
        setReports(prev => prev.map(r => r.id === data.id ? { ...r, ...data } : r));
      }
      setEditMode(false);
    } catch { /* silent */ }
    setSaving(false);
  };

  const assignToMe = async () => {
    if (!selectedReport) return;
    setSaving(true);
    try {
      const { data } = await api.put(`/reports/${selectedReport.id}`, { assigned_to: user.id });
      setSelectedReport(prev => ({ ...prev, ...data }));
      setEditData(prev => ({ ...prev, assigned_to: user.id }));
      setReports(prev => prev.map(r => r.id === data.id ? { ...r, ...data } : r));
    } catch { /* silent */ }
    setSaving(false);
  };

  if (!user) return null;

  return (
    <div className="section">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 24, fontWeight: 800 }}>Gestion des signalements</h2>
          <p style={{ color: 'var(--text-light)', fontSize: 14 }}>{meta.total || 0} signalements au total</p>
        </div>
        <a
          href={`${import.meta.env.VITE_API_URL || 'http://localhost:8081/api'}/reports/export${filters.status ? `?status=${filters.status}` : ''}${filters.priority ? `&priority=${filters.priority}` : ''}`}
          target="_blank"
          rel="noopener noreferrer"
          className="btn btn-outline"
          style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 13 }}
        >
          <Download size={14} /> Exporter CSV
        </a>
      </div>

      {/* Filters bar */}
      <div className="card" style={{ marginBottom: 16, display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'flex-end' }}>
        <div style={{ flex: 1, minWidth: 200 }}>
          <label style={{ fontSize: 12, fontWeight: 600, display: 'block', marginBottom: 4 }}>
            <Search size={12} style={{ verticalAlign: 'middle' }} /> Recherche
          </label>
          <input type="text" placeholder="Référence, description, région..." value={filters.search}
            onChange={e => setFilters(f => ({ ...f, search: e.target.value }))}
            onKeyDown={e => e.key === 'Enter' && fetchReports(1)}
            style={{ width: '100%', padding: '8px 12px', border: '2px solid var(--border)', borderRadius: 8, fontSize: 13 }} />
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
            {Object.entries(PRIORITY_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
          </select>
        </div>
        <div>
          <label style={{ fontSize: 12, fontWeight: 600, display: 'block', marginBottom: 4 }}>Assignation</label>
          <select value={filters.assigned_to} onChange={e => setFilters(f => ({ ...f, assigned_to: e.target.value }))}
            style={{ padding: '8px 12px', border: '2px solid var(--border)', borderRadius: 8, fontSize: 13 }}>
            <option value="">Tous</option>
            <option value="unassigned">Non assignés</option>
          </select>
        </div>
        <button className="btn btn-primary" onClick={() => fetchReports(1)} style={{ fontSize: 13, padding: '8px 16px' }}>
          <Filter size={14} style={{ marginRight: 4 }} /> Filtrer
        </button>
        {(filters.search || filters.status || filters.priority || filters.assigned_to) && (
          <button className="btn btn-outline" onClick={() => { setFilters({ search: '', status: '', priority: '', assigned_to: '' }); }}
            style={{ fontSize: 13, padding: '8px 12px' }}>
            <X size={14} /> Réinitialiser
          </button>
        )}
      </div>

      {/* Reports table */}
      <div className="card" style={{ padding: 0, overflow: 'auto' }}>
        {loading ? <p style={{ padding: 40, textAlign: 'center', color: 'var(--text-light)' }}>Chargement...</p> : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Référence</th>
                <th>Date</th>
                <th>Région</th>
                <th>Types de violence</th>
                <th>Statut</th>
                <th>Priorité</th>
                <th>Assigné à</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {reports.length === 0 ? (
                <tr><td colSpan={8} style={{ textAlign: 'center', color: 'var(--text-light)', padding: 40 }}>Aucun signalement trouvé</td></tr>
              ) : reports.map(r => (
                <tr key={r.id} style={{ cursor: 'pointer' }} onClick={() => openDetail(r)}>
                  <td style={{ fontWeight: 600, color: 'var(--purple)' }}>{r.reference}</td>
                  <td style={{ fontSize: 12, whiteSpace: 'nowrap' }}>{new Date(r.created_at).toLocaleDateString('fr-FR')}</td>
                  <td>{r.region || '-'}</td>
                  <td style={{ fontSize: 12, maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {(r.violence_types || []).map(v => v.label_fr).join(', ') || '-'}
                  </td>
                  <td><span className={`badge ${STATUS_BADGE[r.status] || ''}`}>{STATUS_LABELS[r.status] || r.status}</span></td>
                  <td><span className={`badge ${PRIORITY_BADGE[r.priority] || ''}`}>{r.priority}</span></td>
                  <td style={{ fontSize: 12 }}>{r.assigned_to_user?.name || '—'}</td>
                  <td><button className="btn btn-outline" style={{ fontSize: 11, padding: '4px 10px' }} onClick={e => { e.stopPropagation(); openDetail(r); }}>Détail</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}

        {/* Pagination */}
        {meta.last_page > 1 && (
          <div style={{ padding: 12, display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 8 }}>
            <button className="btn btn-outline" disabled={page <= 1} onClick={() => fetchReports(page - 1)} style={{ padding: '6px 10px', fontSize: 12 }}>
              <ChevronLeft size={14} />
            </button>
            <span style={{ fontSize: 13, color: 'var(--text-light)' }}>Page {page} / {meta.last_page}</span>
            <button className="btn btn-outline" disabled={page >= meta.last_page} onClick={() => fetchReports(page + 1)} style={{ padding: '6px 10px', fontSize: 12 }}>
              <ChevronRight size={14} />
            </button>
          </div>
        )}
      </div>

      {/* ── DETAIL MODAL ── */}
      {selectedReport && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 2000, display: 'flex', justifyContent: 'center', alignItems: 'flex-start', padding: '80px 16px', overflowY: 'auto' }}
          onClick={() => { setSelectedReport(null); setEditMode(false); }}>
          <div style={{ background: 'white', borderRadius: 16, maxWidth: 700, width: '100%', maxHeight: '80vh', overflowY: 'auto' }}
            onClick={e => e.stopPropagation()}>

            {/* Modal header */}
            <div style={{ padding: '20px 24px', borderBottom: '1px solid var(--border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', position: 'sticky', top: 0, background: 'white', borderRadius: '16px 16px 0 0', zIndex: 1 }}>
              <div>
                <h3 style={{ fontSize: 18, fontWeight: 700, color: 'var(--purple)' }}>{selectedReport.reference}</h3>
                <p style={{ fontSize: 12, color: 'var(--text-light)' }}>Créé le {new Date(selectedReport.created_at).toLocaleDateString('fr-FR')}</p>
              </div>
              <div style={{ display: 'flex', gap: 8 }}>
                {!editMode ? (
                  <button className="btn btn-primary" onClick={() => setEditMode(true)} style={{ fontSize: 12, padding: '6px 14px' }}>
                    <Edit3 size={14} style={{ marginRight: 4 }} /> Modifier
                  </button>
                ) : (
                  <>
                    <button className="btn btn-outline" onClick={() => setEditMode(false)} style={{ fontSize: 12, padding: '6px 14px' }}>Annuler</button>
                    <button className="btn btn-primary" onClick={saveChanges} disabled={saving} style={{ fontSize: 12, padding: '6px 14px' }}>
                      <Save size={14} style={{ marginRight: 4 }} /> {saving ? 'Enregistrement...' : 'Enregistrer'}
                    </button>
                  </>
                )}
                <button onClick={() => { setSelectedReport(null); setEditMode(false); }} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 4 }}>
                  <X size={20} color="var(--text-light)" />
                </button>
              </div>
            </div>

            {detailLoading ? <p style={{ padding: 40, textAlign: 'center' }}>Chargement...</p> : (
              <div style={{ padding: 24 }}>
                {/* Status + Priority + Assignment */}
                <div style={{ display: 'flex', gap: 16, marginBottom: 24, flexWrap: 'wrap' }}>
                  <div style={{ flex: 1, minWidth: 150 }}>
                    <label style={{ fontSize: 12, fontWeight: 600, display: 'block', marginBottom: 6, color: 'var(--text-light)' }}>Statut</label>
                    {editMode ? (
                      <select value={editData.status} onChange={e => setEditData(d => ({ ...d, status: e.target.value }))}
                        style={{ width: '100%', padding: '8px 12px', border: '2px solid var(--border)', borderRadius: 8, fontSize: 13 }}>
                        {Object.entries(STATUS_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                      </select>
                    ) : (
                      <span className={`badge ${STATUS_BADGE[selectedReport.status]}`} style={{ fontSize: 13 }}>{STATUS_LABELS[selectedReport.status]}</span>
                    )}
                  </div>
                  <div style={{ flex: 1, minWidth: 150 }}>
                    <label style={{ fontSize: 12, fontWeight: 600, display: 'block', marginBottom: 6, color: 'var(--text-light)' }}>Priorité</label>
                    {editMode ? (
                      <select value={editData.priority} onChange={e => setEditData(d => ({ ...d, priority: e.target.value }))}
                        style={{ width: '100%', padding: '8px 12px', border: '2px solid var(--border)', borderRadius: 8, fontSize: 13 }}>
                        {Object.entries(PRIORITY_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                      </select>
                    ) : (
                      <span className={`badge ${PRIORITY_BADGE[selectedReport.priority]}`} style={{ fontSize: 13 }}>{selectedReport.priority}</span>
                    )}
                  </div>
                  <div style={{ flex: 1, minWidth: 150 }}>
                    <label style={{ fontSize: 12, fontWeight: 600, display: 'block', marginBottom: 6, color: 'var(--text-light)' }}>Assigné à</label>
                    {selectedReport.assigned_to_user ? (
                      <span style={{ fontSize: 13 }}><User size={14} style={{ verticalAlign: 'middle', marginRight: 4 }} />{selectedReport.assigned_to_user.name}</span>
                    ) : (
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <span style={{ fontSize: 13, color: 'var(--text-light)' }}>Non assigné</span>
                        <button className="btn btn-outline" onClick={assignToMe} disabled={saving} style={{ fontSize: 11, padding: '4px 10px' }}>
                          <UserPlus size={12} style={{ marginRight: 2 }} /> Prendre en charge
                        </button>
                      </div>
                    )}
                  </div>
                </div>

                {/* Victim info */}
                <div className="card" style={{ marginBottom: 16, background: 'var(--bg)' }}>
                  <h4 style={{ fontSize: 14, fontWeight: 700, marginBottom: 12 }}>Informations</h4>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px 24px', fontSize: 13 }}>
                    <div><span style={{ color: 'var(--text-light)' }}>Type de déclarant :</span> {selectedReport.reporter_type}</div>
                    <div><span style={{ color: 'var(--text-light)' }}>Genre victime :</span> {selectedReport.victim_gender}</div>
                    <div><span style={{ color: 'var(--text-light)' }}>Tranche d'âge :</span> {selectedReport.victim_age_range || '-'}</div>
                    <div><span style={{ color: 'var(--text-light)' }}>Relation auteur :</span> {selectedReport.perpetrator_relation || '-'}</div>
                    <div><span style={{ color: 'var(--text-light)' }}>Statut victime :</span>
                      {selectedReport.victim_status === 'danger_immediat' ?
                        <span style={{ color: 'var(--danger)', fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: 3 }}> <AlertTriangle size={12} /> Danger immédiat</span> :
                        ` ${selectedReport.victim_status || '-'}`}
                    </div>
                  </div>
                </div>

                {/* Location */}
                <div className="card" style={{ marginBottom: 16, background: 'var(--bg)' }}>
                  <h4 style={{ fontSize: 14, fontWeight: 700, marginBottom: 12 }}>
                    <MapPin size={14} style={{ verticalAlign: 'middle', marginRight: 6 }} />Localisation
                  </h4>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px 24px', fontSize: 13 }}>
                    <div><span style={{ color: 'var(--text-light)' }}>Région :</span> {selectedReport.region || '-'}</div>
                    <div><span style={{ color: 'var(--text-light)' }}>Province :</span> {selectedReport.province || '-'}</div>
                    <div style={{ gridColumn: '1/-1' }}><span style={{ color: 'var(--text-light)' }}>Lieu :</span> {selectedReport.lieu_description || '-'}</div>
                  </div>
                </div>

                {/* Violence types */}
                {selectedReport.violence_types?.length > 0 && (
                  <div style={{ marginBottom: 16 }}>
                    <h4 style={{ fontSize: 14, fontWeight: 700, marginBottom: 8 }}>
                      <AlertTriangle size={14} style={{ verticalAlign: 'middle', marginRight: 6 }} />Types de violence
                    </h4>
                    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                      {selectedReport.violence_types.map(v => (
                        <span key={v.id} className="badge badge-purple" style={{ fontSize: 12 }}>{v.label_fr}</span>
                      ))}
                    </div>
                  </div>
                )}

                {/* Description */}
                <div style={{ marginBottom: 16 }}>
                  <h4 style={{ fontSize: 14, fontWeight: 700, marginBottom: 8 }}>Description des faits</h4>
                  <div style={{ background: 'var(--bg)', padding: 16, borderRadius: 8, fontSize: 14, lineHeight: 1.6, whiteSpace: 'pre-wrap' }}>
                    {selectedReport.description}
                  </div>
                </div>

                {/* Date & contact */}
                <div style={{ display: 'flex', gap: 24, marginBottom: 16, fontSize: 13 }}>
                  {selectedReport.incident_date && (
                    <div><Calendar size={14} style={{ verticalAlign: 'middle', marginRight: 4 }} />
                      <span style={{ color: 'var(--text-light)' }}>Date incident :</span> {new Date(selectedReport.incident_date).toLocaleDateString('fr-FR')}
                    </div>
                  )}
                  {selectedReport.contact_phone && (
                    <div><span style={{ color: 'var(--text-light)' }}>Tél :</span> {selectedReport.contact_phone}</div>
                  )}
                </div>

                {/* Notes internes */}
                <div style={{ marginBottom: 16 }}>
                  <h4 style={{ fontSize: 14, fontWeight: 700, marginBottom: 8 }}>
                    <Shield size={14} style={{ verticalAlign: 'middle', marginRight: 6 }} />Notes internes
                  </h4>
                  {editMode ? (
                    <textarea value={editData.notes} onChange={e => setEditData(d => ({ ...d, notes: e.target.value }))}
                      rows={4} placeholder="Ajouter des notes internes sur ce dossier..."
                      style={{ width: '100%', padding: 12, border: '2px solid var(--border)', borderRadius: 8, fontSize: 13, fontFamily: 'Poppins, sans-serif', resize: 'vertical' }} />
                  ) : (
                    <div style={{ background: '#FFFDE7', padding: 12, borderRadius: 8, fontSize: 13, lineHeight: 1.5, minHeight: 40, whiteSpace: 'pre-wrap' }}>
                      {selectedReport.notes || <span style={{ color: 'var(--text-light)', fontStyle: 'italic' }}>Aucune note</span>}
                    </div>
                  )}
                </div>

                {/* Timestamps */}
                <div style={{ fontSize: 11, color: 'var(--text-light)', display: 'flex', gap: 16 }}>
                  <span><Clock size={11} style={{ verticalAlign: 'middle' }} /> Créé : {new Date(selectedReport.created_at).toLocaleString('fr-FR')}</span>
                  <span>Modifié : {new Date(selectedReport.updated_at).toLocaleString('fr-FR')}</span>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
