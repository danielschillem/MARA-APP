import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useToast } from '../components/Toast';
import api from '../api';
import {
    Users, UserPlus, Pencil, Trash2, Search, X,
    ShieldCheck, CheckCircle, RefreshCw
} from 'lucide-react';

const ROLES = [
    { value: 'admin', label: 'Administrateur', color: '#B5103C' },
    { value: 'professionnel', label: 'Professionnel', color: '#7B2FBE' },
    { value: 'conseiller', label: 'Conseiller', color: '#2D6A4F' },
    { value: 'coordinateur', label: 'Coordinateur', color: '#1A2E4A' },
];

const roleMeta = Object.fromEntries(ROLES.map(r => [r.value, r]));

const emptyForm = {
    name: '', email: '', password: '', role: 'conseiller',
    titre: '', specialite: '', organisation: '', zone: '',
};

export default function AdminPage() {
    const { user } = useAuth();
    const navigate = useNavigate();
    const { showToast } = useToast();

    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [roleFilter, setRoleFilter] = useState('');
    const [modal, setModal] = useState(null); // null | 'create' | 'edit'
    const [editTarget, setEditTarget] = useState(null);
    const [form, setForm] = useState(emptyForm);
    const [saving, setSaving] = useState(false);
    const [deleting, setDeleting] = useState(null);

    useEffect(() => {
        if (!user || user.role !== 'admin') { navigate('/dashboard'); return; }
        fetchUsers();
    }, [user]);

    const fetchUsers = useCallback(async () => {
        setLoading(true);
        try {
            const params = {};
            if (roleFilter) params.role = roleFilter;
            if (search) params.search = search;
            const { data } = await api.get('/admin/users', { params });
            setUsers(data);
        } catch {
            showToast('Erreur lors du chargement', 'error');
        }
        setLoading(false);
    }, [roleFilter, search]);

    useEffect(() => {
        const timer = setTimeout(() => fetchUsers(), 300);
        return () => clearTimeout(timer);
    }, [fetchUsers]);

    const openCreate = () => {
        setForm(emptyForm);
        setEditTarget(null);
        setModal('create');
    };

    const openEdit = (u) => {
        setForm({
            name: u.name, email: u.email, password: '',
            role: u.role, titre: u.titre || '',
            specialite: u.specialite || '', organisation: u.organisation || '',
            zone: u.zone || '',
        });
        setEditTarget(u);
        setModal('edit');
    };

    const closeModal = () => { setModal(null); setEditTarget(null); setForm(emptyForm); };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setSaving(true);
        try {
            if (modal === 'create') {
                await api.post('/admin/users', form);
                showToast('Utilisateur créé', 'success');
            } else {
                const payload = { ...form };
                if (!payload.password) delete payload.password;
                await api.put(`/admin/users/${editTarget.id}`, payload);
                showToast('Utilisateur mis à jour', 'success');
            }
            closeModal();
            fetchUsers();
        } catch (err) {
            showToast(err?.response?.data?.error || 'Erreur', 'error');
        }
        setSaving(false);
    };

    const handleDelete = async (u) => {
        if (!window.confirm(`Supprimer ${u.name} ?`)) return;
        setDeleting(u.id);
        try {
            await api.delete(`/admin/users/${u.id}`);
            showToast('Utilisateur supprimé', 'success');
            setUsers(prev => prev.filter(x => x.id !== u.id));
        } catch {
            showToast('Suppression impossible', 'error');
        }
        setDeleting(null);
    };

    if (!user) return null;

    return (
        <div className="section">
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24, flexWrap: 'wrap', gap: 12 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <ShieldCheck size={28} color="var(--purple)" />
                    <div>
                        <h2 style={{ margin: 0 }}>Administration</h2>
                        <p style={{ margin: 0, color: 'var(--text-light)', fontSize: 13 }}>Gestion des utilisateurs MARA</p>
                    </div>
                </div>
                <button className="btn btn-primary" onClick={openCreate} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <UserPlus size={16} /> Nouvel utilisateur
                </button>
            </div>

            {/* Filters */}
            <div style={{ display: 'flex', gap: 12, marginBottom: 20, flexWrap: 'wrap' }}>
                <div style={{ position: 'relative', flex: 1, minWidth: 200 }}>
                    <Search size={16} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--text-light)' }} />
                    <input
                        type="text"
                        placeholder="Rechercher nom ou email…"
                        value={search}
                        onChange={e => setSearch(e.target.value)}
                        style={{ paddingLeft: 36, width: '100%' }}
                    />
                </div>
                <select value={roleFilter} onChange={e => setRoleFilter(e.target.value)} style={{ minWidth: 160 }}>
                    <option value="">Tous les rôles</option>
                    {ROLES.map(r => <option key={r.value} value={r.value}>{r.label}</option>)}
                </select>
                <button className="btn btn-outline" onClick={fetchUsers} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <RefreshCw size={14} /> Actualiser
                </button>
            </div>

            {/* Stats row */}
            <div className="grid-4" style={{ marginBottom: 24 }}>
                {ROLES.map(r => {
                    const count = users.filter(u => u.role === r.value).length;
                    return (
                        <div key={r.value} className="card" style={{ textAlign: 'center', padding: '16px 12px' }}>
                            <span style={{ fontSize: 28, fontWeight: 700, color: r.color }}>{count}</span>
                            <p style={{ margin: 0, fontSize: 12, color: 'var(--text-light)' }}>{r.label}</p>
                        </div>
                    );
                })}
            </div>

            {/* Table */}
            {loading ? (
                <div style={{ textAlign: 'center', padding: 48 }}>
                    <RefreshCw size={24} className="spin" color="var(--purple)" />
                </div>
            ) : (
                <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                        <thead>
                            <tr style={{ background: 'var(--bg)', borderBottom: '1px solid var(--border)' }}>
                                {['Utilisateur', 'Rôle', 'Organisation', 'Zone', 'Statut', 'Actions'].map(h => (
                                    <th key={h} style={{ padding: '10px 16px', textAlign: 'left', fontSize: 12, fontWeight: 600, color: 'var(--text-light)', whiteSpace: 'nowrap' }}>{h}</th>
                                ))}
                            </tr>
                        </thead>
                        <tbody>
                            {users.length === 0 ? (
                                <tr><td colSpan={6} style={{ textAlign: 'center', padding: 32, color: 'var(--text-light)' }}>Aucun utilisateur trouvé</td></tr>
                            ) : users.map(u => {
                                const meta = roleMeta[u.role] || { label: u.role, color: '#888' };
                                return (
                                    <tr key={u.id} style={{ borderBottom: '1px solid var(--border)', transition: 'background 0.1s' }}
                                        onMouseEnter={e => e.currentTarget.style.background = 'var(--bg)'}
                                        onMouseLeave={e => e.currentTarget.style.background = ''}
                                    >
                                        <td style={{ padding: '12px 16px' }}>
                                            <div style={{ fontWeight: 600, fontSize: 14 }}>{u.name}</div>
                                            <div style={{ fontSize: 12, color: 'var(--text-light)' }}>{u.email}</div>
                                            {u.titre && <div style={{ fontSize: 11, color: 'var(--text-light)' }}>{u.titre}</div>}
                                        </td>
                                        <td style={{ padding: '12px 16px' }}>
                                            <span style={{ background: meta.color + '18', color: meta.color, padding: '3px 10px', borderRadius: 20, fontSize: 12, fontWeight: 600 }}>
                                                {meta.label}
                                            </span>
                                        </td>
                                        <td style={{ padding: '12px 16px', fontSize: 13, color: 'var(--text-light)' }}>{u.organisation || '—'}</td>
                                        <td style={{ padding: '12px 16px', fontSize: 13, color: 'var(--text-light)' }}>{u.zone || '—'}</td>
                                        <td style={{ padding: '12px 16px' }}>
                                            {u.is_online
                                                ? <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: 'var(--success)', fontSize: 12 }}><CheckCircle size={12} /> En ligne</span>
                                                : <span style={{ fontSize: 12, color: 'var(--text-light)' }}>Hors ligne</span>
                                            }
                                        </td>
                                        <td style={{ padding: '12px 16px' }}>
                                            <div style={{ display: 'flex', gap: 6 }}>
                                                <button
                                                    onClick={() => openEdit(u)}
                                                    style={{ background: 'var(--purple-xlight)', color: 'var(--purple)', border: 'none', borderRadius: 8, padding: '6px 10px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4, fontSize: 12 }}
                                                >
                                                    <Pencil size={12} /> Modifier
                                                </button>
                                                {u.id !== user.id && (
                                                    <button
                                                        onClick={() => handleDelete(u)}
                                                        disabled={deleting === u.id}
                                                        style={{ background: '#fff0f3', color: 'var(--danger)', border: 'none', borderRadius: 8, padding: '6px 10px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 4, fontSize: 12 }}
                                                    >
                                                        {deleting === u.id ? <RefreshCw size={12} className="spin" /> : <Trash2 size={12} />} Suppr.
                                                    </button>
                                                )}
                                            </div>
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                </div>
            )}

            {/* Modal */}
            {modal && (
                <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: 16 }}>
                    <div className="card" style={{ width: '100%', maxWidth: 520, maxHeight: '90vh', overflow: 'auto' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
                            <h3 style={{ margin: 0 }}>{modal === 'create' ? 'Nouvel utilisateur' : `Modifier ${editTarget?.name}`}</h3>
                            <button onClick={closeModal} style={{ background: 'none', border: 'none', cursor: 'pointer' }}><X size={20} /></button>
                        </div>
                        <form onSubmit={handleSubmit}>
                            <div style={{ display: 'grid', gap: 14 }}>
                                <div className="grid-2" style={{ gap: 12 }}>
                                    <div>
                                        <label className="form-label">Nom complet *</label>
                                        <input className="form-input" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} required />
                                    </div>
                                    <div>
                                        <label className="form-label">Email *</label>
                                        <input className="form-input" type="email" value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))} required />
                                    </div>
                                </div>
                                <div className="grid-2" style={{ gap: 12 }}>
                                    <div>
                                        <label className="form-label">{modal === 'create' ? 'Mot de passe *' : 'Nouveau mot de passe'}</label>
                                        <input className="form-input" type="password" value={form.password} onChange={e => setForm(f => ({ ...f, password: e.target.value }))} required={modal === 'create'} minLength={8} placeholder={modal === 'edit' ? 'Laisser vide pour ne pas changer' : ''} />
                                    </div>
                                    <div>
                                        <label className="form-label">Rôle</label>
                                        <select className="form-input" value={form.role} onChange={e => setForm(f => ({ ...f, role: e.target.value }))}>
                                            {ROLES.map(r => <option key={r.value} value={r.value}>{r.label}</option>)}
                                        </select>
                                    </div>
                                </div>
                                <div className="grid-2" style={{ gap: 12 }}>
                                    <div>
                                        <label className="form-label">Titre</label>
                                        <input className="form-input" value={form.titre} onChange={e => setForm(f => ({ ...f, titre: e.target.value }))} placeholder="Ex: Psychologue" />
                                    </div>
                                    <div>
                                        <label className="form-label">Spécialité</label>
                                        <input className="form-input" value={form.specialite} onChange={e => setForm(f => ({ ...f, specialite: e.target.value }))} />
                                    </div>
                                </div>
                                <div className="grid-2" style={{ gap: 12 }}>
                                    <div>
                                        <label className="form-label">Organisation</label>
                                        <input className="form-input" value={form.organisation} onChange={e => setForm(f => ({ ...f, organisation: e.target.value }))} />
                                    </div>
                                    <div>
                                        <label className="form-label">Zone</label>
                                        <input className="form-input" value={form.zone} onChange={e => setForm(f => ({ ...f, zone: e.target.value }))} placeholder="Ex: Ouagadougou" />
                                    </div>
                                </div>
                                <div style={{ display: 'flex', gap: 12, justifyContent: 'flex-end', marginTop: 8 }}>
                                    <button type="button" className="btn btn-outline" onClick={closeModal}>Annuler</button>
                                    <button type="submit" className="btn btn-primary" disabled={saving}>
                                        {saving ? <RefreshCw size={14} className="spin" /> : modal === 'create' ? <><UserPlus size={14} /> Créer</> : <><CheckCircle size={14} /> Enregistrer</>}
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
