import { useState, useMemo } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { Eye, EyeOff, Check, X, Shield } from 'lucide-react';
import MaraLogo from '../components/MaraLogo';

const PASSWORD_RULES = [
  { key: 'min', test: p => p.length >= 8, label: '8 caractères minimum' },
  { key: 'upper', test: p => /[A-Z]/.test(p), label: 'Une majuscule' },
  { key: 'lower', test: p => /[a-z]/.test(p), label: 'Une minuscule' },
  { key: 'number', test: p => /[0-9]/.test(p), label: 'Un chiffre' },
  { key: 'symbol', test: p => /[^A-Za-z0-9]/.test(p), label: 'Un caractère spécial' },
];

export default function RegisterPage() {
  const { register } = useAuth();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [form, setForm] = useState({ name: '', email: '', password: '', password_confirmation: '', role: 'conseiller' });
  const [error, setError] = useState('');
  const [fieldErrors, setFieldErrors] = useState({});
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  const update = (field, value) => {
    setForm(prev => ({ ...prev, [field]: value }));
    setFieldErrors(prev => ({ ...prev, [field]: '' }));
  };

  const passwordChecks = useMemo(() =>
    PASSWORD_RULES.map(r => ({ ...r, passed: r.test(form.password) })),
    [form.password]
  );
  const passwordStrength = passwordChecks.filter(r => r.passed).length;
  const strengthColor = passwordStrength <= 2 ? 'var(--danger)' : passwordStrength <= 3 ? 'var(--warning)' : passwordStrength <= 4 ? 'var(--orange)' : 'var(--success)';
  const strengthLabel = passwordStrength <= 2 ? 'Faible' : passwordStrength <= 3 ? 'Moyen' : passwordStrength <= 4 ? 'Bon' : 'Fort';

  const validateForm = () => {
    const errs = {};
    if (!form.name.trim()) errs.name = 'Le nom est requis.';
    if (!form.email.trim()) errs.email = "L'email est requis.";
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) errs.email = 'Email invalide.';
    if (passwordStrength < 5) errs.password = 'Le mot de passe ne respecte pas tous les critères.';
    if (form.password !== form.password_confirmation) errs.password_confirmation = 'Les mots de passe ne correspondent pas.';
    setFieldErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    if (!validateForm()) return;
    setLoading(true);
    try {
      await register(form);
      navigate('/dashboard');
    } catch (err) {
      const msg = err.response?.data?.errors
        ? Object.values(err.response.data.errors).flat().join(', ')
        : err.response?.data?.message || t('register.defaultError');
      setError(msg);
    }
    setLoading(false);
  };

  const FieldError = ({ msg }) => msg ? <p style={{ color: 'var(--danger)', fontSize: 12, marginTop: 4 }}>{msg}</p> : null;

  return (
    <div className="section" style={{ maxWidth: 440, paddingTop: 80 }}>
      <div className="section-title">
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 16 }}>
          <MaraLogo size="md" />
        </div>
        <h2>{t('register.title')}</h2>
        <p>{t('register.subtitle')}</p>
      </div>

      <div className="card">
        {error && (
          <div style={{ background: '#ffebee', color: 'var(--danger)', padding: 12, borderRadius: 8, marginBottom: 16, fontSize: 13, display: 'flex', alignItems: 'center', gap: 8 }}>
            <X size={16} style={{ flexShrink: 0 }} /> {error}
          </div>
        )}
        <form onSubmit={handleSubmit} noValidate>
          <div className="form-group">
            <label className="form-label">{t('register.name')}</label>
            <input className="form-input" value={form.name} onChange={e => update('name', e.target.value)}
              style={fieldErrors.name ? { borderColor: 'var(--danger)' } : {}} placeholder="Votre nom complet" />
            <FieldError msg={fieldErrors.name} />
          </div>
          <div className="form-group">
            <label className="form-label">{t('register.email')}</label>
            <input className="form-input" type="email" value={form.email} onChange={e => update('email', e.target.value)}
              style={fieldErrors.email ? { borderColor: 'var(--danger)' } : {}} placeholder="votre@email.com" />
            <FieldError msg={fieldErrors.email} />
          </div>
          <div className="form-group">
            <label className="form-label">{t('register.role')}</label>
            <select className="form-select" value={form.role} onChange={e => update('role', e.target.value)}>
              <option value="conseiller">{t('register.roleConseiller')}</option>
              <option value="professionnel">{t('register.rolePro')}</option>
            </select>
          </div>
          <div className="form-group">
            <label className="form-label">{t('register.password')}</label>
            <div style={{ position: 'relative' }}>
              <input className="form-input" type={showPassword ? 'text' : 'password'} value={form.password}
                onChange={e => update('password', e.target.value)}
                style={{ paddingRight: 40, ...(fieldErrors.password ? { borderColor: 'var(--danger)' } : {}) }}
                placeholder="••••••••" />
              <button type="button" onClick={() => setShowPassword(v => !v)}
                style={{ position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-light)', padding: 4 }}
                aria-label={showPassword ? 'Masquer' : 'Afficher'}>
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
            <FieldError msg={fieldErrors.password} />

            {/* Password strength */}
            {form.password && (
              <div style={{ marginTop: 10 }}>
                <div style={{ display: 'flex', gap: 3, marginBottom: 6 }}>
                  {[1, 2, 3, 4, 5].map(i => (
                    <div key={i} style={{
                      flex: 1, height: 4, borderRadius: 4,
                      background: i <= passwordStrength ? strengthColor : 'var(--border)',
                      transition: 'background .3s'
                    }} />
                  ))}
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8 }}>
                  <Shield size={13} color={strengthColor} />
                  <span style={{ fontSize: 12, fontWeight: 600, color: strengthColor }}>{strengthLabel}</span>
                </div>
                <div style={{ display: 'grid', gap: 3 }}>
                  {passwordChecks.map(r => (
                    <div key={r.key} style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: r.passed ? 'var(--success)' : 'var(--text-light)' }}>
                      {r.passed ? <Check size={13} /> : <X size={13} />} {r.label}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
          <div className="form-group">
            <label className="form-label">{t('register.confirmPassword')}</label>
            <div style={{ position: 'relative' }}>
              <input className="form-input" type={showConfirm ? 'text' : 'password'} value={form.password_confirmation}
                onChange={e => update('password_confirmation', e.target.value)}
                style={{ paddingRight: 40, ...(fieldErrors.password_confirmation ? { borderColor: 'var(--danger)' } : {}) }}
                placeholder="••••••••" />
              <button type="button" onClick={() => setShowConfirm(v => !v)}
                style={{ position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-light)', padding: 4 }}
                aria-label={showConfirm ? 'Masquer' : 'Afficher'}>
                {showConfirm ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
            <FieldError msg={fieldErrors.password_confirmation} />
            {form.password_confirmation && form.password === form.password_confirmation && (
              <p style={{ color: 'var(--success)', fontSize: 12, marginTop: 4, display: 'flex', alignItems: 'center', gap: 4 }}>
                <Check size={13} /> Les mots de passe correspondent
              </p>
            )}
          </div>
          <button className="btn btn-primary" type="submit" disabled={loading} style={{ width: '100%', justifyContent: 'center', marginTop: 8 }}>
            {loading ? t('register.loading') : t('register.submit')}
          </button>
        </form>
        <div style={{ textAlign: 'center', marginTop: 16 }}>
          <Link to="/login" style={{ fontSize: 13, color: 'var(--purple)', fontWeight: 600 }}>
            {t('register.alreadyAccount')}
          </Link>
        </div>
      </div>
    </div>
  );
}
