import { useState, useMemo } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useToast } from '../components/Toast';
import { User, Lock, Shield, Check, X, Eye, EyeOff } from 'lucide-react';
import api from '../api';

const PASSWORD_RULES = [
  { key: 'min', test: p => p.length >= 8, label: '8 caractères minimum' },
  { key: 'upper', test: p => /[A-Z]/.test(p), label: 'Une majuscule' },
  { key: 'lower', test: p => /[a-z]/.test(p), label: 'Une minuscule' },
  { key: 'number', test: p => /[0-9]/.test(p), label: 'Un chiffre' },
  { key: 'symbol', test: p => /[^A-Za-z0-9]/.test(p), label: 'Un caractère spécial' },
];

const ROLE_LABELS = {
  admin: 'Administrateur',
  professionnel: 'Professionnel',
  conseiller: 'Conseiller',
};

export default function ProfilePage() {
  const { user } = useAuth();
  const { addToast } = useToast();
  const [form, setForm] = useState({ current_password: '', password: '', password_confirmation: '' });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [showCurrent, setShowCurrent] = useState(false);
  const [showNew, setShowNew] = useState(false);

  const passwordChecks = useMemo(() =>
    PASSWORD_RULES.map(r => ({ ...r, passed: r.test(form.password) })),
    [form.password]
  );
  const passwordStrength = passwordChecks.filter(r => r.passed).length;
  const strengthColor = passwordStrength <= 2 ? 'var(--danger)' : passwordStrength <= 3 ? 'var(--warning)' : passwordStrength <= 4 ? 'var(--orange)' : 'var(--success)';

  const handleChangePassword = async (e) => {
    e.preventDefault();
    setError('');
    if (passwordStrength < 5) { setError('Le mot de passe ne respecte pas tous les critères.'); return; }
    if (form.password !== form.password_confirmation) { setError('Les mots de passe ne correspondent pas.'); return; }
    setLoading(true);
    try {
      await api.post('/change-password', form);
      addToast('Mot de passe modifié avec succès !', 'success');
      setForm({ current_password: '', password: '', password_confirmation: '' });
    } catch (err) {
      const msg = err.response?.data?.errors
        ? Object.values(err.response.data.errors).flat().join(', ')
        : err.response?.data?.message || 'Erreur lors du changement de mot de passe.';
      setError(msg);
    }
    setLoading(false);
  };

  if (!user) return (
    <div className="section" style={{ textAlign: 'center', paddingTop: 100 }}>
      <p>Veuillez vous connecter pour accéder à votre profil.</p>
    </div>
  );

  return (
    <div className="section" style={{ maxWidth: 600 }}>
      <div className="section-title">
        <h2>Mon Profil</h2>
        <p>Gérez vos informations et votre sécurité</p>
      </div>

      {/* User Info Card */}
      <div className="card" style={{ marginBottom: 24 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 20 }}>
          <div style={{ width: 56, height: 56, borderRadius: '50%', background: 'linear-gradient(135deg, var(--purple), var(--orange))', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <User size={28} color="white" />
          </div>
          <div>
            <h3 style={{ margin: 0 }}>{user.name}</h3>
            <p style={{ color: 'var(--text-light)', fontSize: 13, margin: 0 }}>{user.email}</p>
          </div>
        </div>
        <div style={{ display: 'grid', gap: 12 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0', borderBottom: '1px solid var(--border)' }}>
            <span style={{ color: 'var(--text-light)', fontSize: 13 }}>Rôle</span>
            <span className="badge badge-purple">{ROLE_LABELS[user.role] || user.role}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 0' }}>
            <span style={{ color: 'var(--text-light)', fontSize: 13 }}>Membre depuis</span>
            <strong style={{ fontSize: 13 }}>{new Date(user.created_at).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })}</strong>
          </div>
        </div>
      </div>

      {/* Change Password Card */}
      <div className="card">
        <h3 style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 20 }}>
          <Lock size={20} color="var(--purple)" /> Changer le mot de passe
        </h3>

        {error && (
          <div style={{ background: '#ffebee', color: 'var(--danger)', padding: 12, borderRadius: 8, marginBottom: 16, fontSize: 13, display: 'flex', alignItems: 'center', gap: 8 }}>
            <X size={16} style={{ flexShrink: 0 }} /> {error}
          </div>
        )}

        <form onSubmit={handleChangePassword}>
          <div className="form-group">
            <label className="form-label">Mot de passe actuel</label>
            <div style={{ position: 'relative' }}>
              <input className="form-input" type={showCurrent ? 'text' : 'password'} value={form.current_password}
                onChange={e => setForm(f => ({ ...f, current_password: e.target.value }))}
                style={{ paddingRight: 40 }} autoComplete="current-password" />
              <button type="button" onClick={() => setShowCurrent(v => !v)}
                style={{ position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-light)', padding: 4 }}>
                {showCurrent ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Nouveau mot de passe</label>
            <div style={{ position: 'relative' }}>
              <input className="form-input" type={showNew ? 'text' : 'password'} value={form.password}
                onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                style={{ paddingRight: 40 }} autoComplete="new-password" />
              <button type="button" onClick={() => setShowNew(v => !v)}
                style={{ position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-light)', padding: 4 }}>
                {showNew ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
            {form.password && (
              <div style={{ marginTop: 8 }}>
                <div style={{ display: 'flex', gap: 3, marginBottom: 6 }}>
                  {[1, 2, 3, 4, 5].map(i => (
                    <div key={i} style={{ flex: 1, height: 4, borderRadius: 4, background: i <= passwordStrength ? strengthColor : 'var(--border)', transition: 'background .3s' }} />
                  ))}
                </div>
                <div style={{ display: 'grid', gap: 2 }}>
                  {passwordChecks.map(r => (
                    <div key={r.key} style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11, color: r.passed ? 'var(--success)' : 'var(--text-light)' }}>
                      {r.passed ? <Check size={12} /> : <X size={12} />} {r.label}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          <div className="form-group">
            <label className="form-label">Confirmer le nouveau mot de passe</label>
            <input className="form-input" type="password" value={form.password_confirmation}
              onChange={e => setForm(f => ({ ...f, password_confirmation: e.target.value }))}
              autoComplete="new-password" />
            {form.password_confirmation && form.password === form.password_confirmation && (
              <p style={{ color: 'var(--success)', fontSize: 12, marginTop: 4, display: 'flex', alignItems: 'center', gap: 4 }}>
                <Check size={13} /> Les mots de passe correspondent
              </p>
            )}
          </div>

          <button className="btn btn-primary" type="submit" disabled={loading || !form.current_password || !form.password}
            style={{ width: '100%', justifyContent: 'center' }}>
            <Shield size={16} /> {loading ? 'Modification...' : 'Modifier le mot de passe'}
          </button>
        </form>
      </div>
    </div>
  );
}
