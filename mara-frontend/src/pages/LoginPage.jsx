import { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { Eye, EyeOff, AlertTriangle } from 'lucide-react';
import MaraLogo from '../components/MaraLogo';

export default function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    if (!email.trim() || !password) {
      setError('Veuillez remplir tous les champs.');
      return;
    }
    setLoading(true);
    try {
      await login(email, password);
      navigate('/dashboard');
    } catch (err) {
      if (err.response?.status === 429) {
        setError('Trop de tentatives. Veuillez réessayer dans quelques minutes.');
      } else {
        setError(err.response?.data?.message || t('login.defaultError'));
      }
    }
    setLoading(false);
  };

  return (
    <div className="section" style={{ maxWidth: 440, paddingTop: 80 }}>
      <div className="section-title">
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 16 }}>
          <MaraLogo size="md" />
        </div>
        <h2>{t('login.title')}</h2>
        <p>{t('login.subtitle')}</p>
      </div>

      <div className="card">
        {error && (
          <div style={{ background: '#ffebee', color: 'var(--danger)', padding: 12, borderRadius: 8, marginBottom: 16, fontSize: 13, display: 'flex', alignItems: 'center', gap: 8 }}>
            <AlertTriangle size={16} style={{ flexShrink: 0 }} /> {error}
          </div>
        )}
        <form onSubmit={handleSubmit} noValidate>
          <div className="form-group">
            <label className="form-label">{t('login.email')}</label>
            <input className="form-input" type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="votre@email.com" autoComplete="email" />
          </div>
          <div className="form-group">
            <label className="form-label">{t('login.password')}</label>
            <div style={{ position: 'relative' }}>
              <input className="form-input" type={showPassword ? 'text' : 'password'} value={password}
                onChange={e => setPassword(e.target.value)} placeholder="••••••••"
                style={{ paddingRight: 40 }} autoComplete="current-password" />
              <button type="button" onClick={() => setShowPassword(v => !v)}
                style={{ position: 'absolute', right: 10, top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-light)', padding: 4 }}
                aria-label={showPassword ? 'Masquer le mot de passe' : 'Afficher le mot de passe'}>
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </div>
          <button className="btn btn-primary" type="submit" disabled={loading} style={{ width: '100%', justifyContent: 'center', marginTop: 8 }}>
            {loading ? t('login.loading') : t('login.submit')}
          </button>
        </form>

        <div style={{ textAlign: 'center', marginTop: 24 }}>
          <Link to="/register" style={{ fontSize: 13, color: 'var(--purple)', fontWeight: 600 }}>
            {t('login.createAccount')}
          </Link>
        </div>

        {/* Demo credentials */}
        <div style={{ marginTop: 24, padding: 12, background: 'var(--purple-xlight)', borderRadius: 8, fontSize: 12 }}>
          <strong>{t('login.demoTitle')}</strong>
          <div style={{ marginTop: 6, color: 'var(--text-light)' }}>
            Admin : admin@mara.bf / password<br />
            Pro : aminata@mara.bf / password<br />
            Conseiller : mariam@mara.bf / password
          </div>
        </div>
      </div>
    </div>
  );
}
