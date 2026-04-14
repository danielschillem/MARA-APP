import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useToast } from '../components/Toast';
import api from '../api';
import { User, MapPin, UserPlus, X, Eye, EyeOff } from 'lucide-react';

const STATUS_COLORS = {
  active: { bg: '#EAF5EE', color: '#2D6A4F', label: 'Actif' },
  busy: { bg: '#FDF5E8', color: '#B87A1A', label: 'Occupé' },
  off: { bg: '#F5F5F0', color: '#999999', label: 'Absent' },
};

const ROLES = [
  { value: 'coordinateur', label: 'Coordinateur' },
  { value: 'conseiller', label: 'Conseiller' },
  { value: 'professionnel', label: 'Professionnel' },
  { value: 'admin', label: 'Administrateur' },
];

const EMPTY_FORM = { name: '', email: '', password: '', role: 'coordinateur', titre: '', organisation: '', zone: '' };

function deriveStatus(member) {
  if (member.is_online && (member.active_cases || 0) === 0) return 'active';
  if (member.is_online) return 'busy';
  return 'off';
}

export default function TeamPage() {
  const { user } = useAuth();
  const { addToast } = useToast();
  const navigate = useNavigate();
  const [team, setTeam] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [showPw, setShowPw] = useState(false);

  const loadTeam = () => {
    api.get('/team').then(r => setTeam(r.data)).catch(() => { }).finally(() => setLoading(false));
  };

  useEffect(() => {
    if (!user) { navigate('/login'); return; }
    loadTeam();
  }, [user]);

  if (!user) return null;

  const active = team.filter(m => deriveStatus(m) !== 'off').length;

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.name || !form.email || !form.password) {
      addToast('Nom, email et mot de passe requis.', 'error'); return;
    }
    setSaving(true);
    try {
      await api.post('/admin/users', form);
      addToast('Membre ajouté avec succès !', 'success');
      setShowModal(false);
      setForm(EMPTY_FORM);
      loadTeam();
    } catch (err) {
      addToast(err?.response?.data?.error || 'Erreur lors de la création.', 'error');
    }
    setSaving(false);
  };

  return (
    <div className="section">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 24, fontWeight: 800 }}>Équipe de coordination</h2>
          <p style={{ color: 'var(--text-light)', fontSize: 14 }}>
            {team.length} membre{team.length !== 1 ? 's' : ''} · {active} actif{active !== 1 ? 's' : ''} en ce moment
          </p>
        </div>
        {user.role === 'admin' && (
          <button className="btn btn-primary" style={{ gap: 6 }} onClick={() => setShowModal(true)}>
            <UserPlus size={15} /> Ajouter un membre
          </button>
        )}
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: 60, color: 'var(--text-light)' }}>Chargement…</div>
      ) : team.length === 0 ? (
        <div className="card" style={{ textAlign: 'center', padding: 60, color: 'var(--text-light)' }}>
          <User size={40} style={{ opacity: 0.3, marginBottom: 12 }} />
          <p>Aucun membre dans l'équipe pour l'instant.</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {team.map(member => {
            const st = STATUS_COLORS[deriveStatus(member)];
            return (
              <div key={member.id} className="card" style={{ padding: '16px 20px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                  <div style={{
                    width: 48, height: 48, borderRadius: '50%',
                    background: 'linear-gradient(135deg, #1A2E4A, #2A4870)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 16, fontWeight: 700, color: '#fff', flexShrink: 0,
                  }}>
                    {member.name.slice(0, 2).toUpperCase()}
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
                      <span style={{ fontSize: 15, fontWeight: 700 }}>{member.name}</span>
                      <span style={{ padding: '2px 8px', borderRadius: 20, fontSize: 10, fontWeight: 700, background: st.bg, color: st.color }}>
                        {st.label}
                      </span>
                    </div>
                    <div style={{ fontSize: 12, color: 'var(--text-light)', marginTop: 2 }}>
                      {member.titre || ROLES.find(r => r.value === member.role)?.label || member.role}
                      {member.organisation && ` · ${member.organisation}`}
                    </div>
                    {member.zone && (
                      <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: 'var(--text-light)', marginTop: 4 }}>
                        <MapPin size={10} /> {member.zone}
                      </div>
                    )}
                  </div>
                  <div style={{ display: 'flex', gap: 16, textAlign: 'center' }}>
                    <div>
                      <div style={{ fontSize: 20, fontWeight: 800, color: '#B87A1A' }}>{member.active_cases ?? 0}</div>
                      <div style={{ fontSize: 10, color: 'var(--text-light)' }}>En cours</div>
                    </div>
                    <div>
                      <div style={{ fontSize: 20, fontWeight: 800, color: '#2D6A4F' }}>{member.resolved_cases ?? 0}</div>
                      <div style={{ fontSize: 10, color: 'var(--text-light)' }}>Résolus</div>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* ── Add member modal ── */}
      {showModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }}>
          <div className="card" style={{ width: '100%', maxWidth: 480, maxHeight: '90vh', overflowY: 'auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
              <h3 style={{ margin: 0, fontSize: 18, fontWeight: 700 }}>Ajouter un membre</h3>
              <button onClick={() => { setShowModal(false); setForm(EMPTY_FORM); }}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-light)' }}>
                <X size={20} />
              </button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label className="form-label">Nom complet *</label>
                <input className="form-input" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} placeholder="Prénom NOM" />
              </div>
              <div className="form-group">
                <label className="form-label">Email *</label>
                <input className="form-input" type="email" value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))} placeholder="email@exemple.bf" />
              </div>
              <div className="form-group">
                <label className="form-label">Mot de passe *</label>
                <div style={{ position: 'relative' }}>
                  <input className="form-input" type={showPw ? 'text' : 'password'} value={form.password}
                    onChange={e => setForm(f => ({ ...f, password: e.target.value }))} style={{ paddingRight: 40 }} placeholder="Min. 8 caractères" />
                  <button type="button" onClick={() => setShowPw(v => !v)}
                    style={{ position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-light)' }}>
                    {showPw ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>
              <div className="form-group">
                <label className="form-label">Rôle</label>
                <select className="form-input" value={form.role} onChange={e => setForm(f => ({ ...f, role: e.target.value }))}>
                  {ROLES.map(r => <option key={r.value} value={r.value}>{r.label}</option>)}
                </select>
              </div>
              <div className="grid-2" style={{ gap: 12 }}>
                <div className="form-group">
                  <label className="form-label">Titre / Fonction</label>
                  <input className="form-input" value={form.titre} onChange={e => setForm(f => ({ ...f, titre: e.target.value }))} placeholder="ex. Travailleur social" />
                </div>
                <div className="form-group">
                  <label className="form-label">Organisation</label>
                  <input className="form-input" value={form.organisation} onChange={e => setForm(f => ({ ...f, organisation: e.target.value }))} placeholder="ex. ONEF" />
                </div>
              </div>
              <div className="form-group">
                <label className="form-label">Zone d'intervention</label>
                <input className="form-input" value={form.zone} onChange={e => setForm(f => ({ ...f, zone: e.target.value }))} placeholder="ex. Ouagadougou" />
              </div>
              <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end', marginTop: 8 }}>
                <button type="button" className="btn btn-outline" onClick={() => { setShowModal(false); setForm(EMPTY_FORM); }}>Annuler</button>
                <button type="submit" className="btn btn-primary" disabled={saving}>
                  {saving ? 'Enregistrement...' : 'Ajouter le membre'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
