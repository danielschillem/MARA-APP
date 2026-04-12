import { NavLink, Outlet, useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useTranslation } from 'react-i18next';
import { LANGUAGES } from '../i18n';
import { useState, useEffect } from 'react';
import {
  Shield, LogOut, User, Globe, Menu, X, Phone,
  Home, FileText, ClipboardList, MessageCircle,
  LayoutDashboard, AlertTriangle, MessagesSquare,
  BookOpen, MapPin, Moon, Sun, BarChart3
} from 'lucide-react';
import MaraLogo from './MaraLogo';
import TextToSpeech from './TextToSpeech';
import api from '../api';

const NAV_ITEMS_PUBLIC = [
  { to: '/', icon: Home, labelKey: 'nav.home', end: true },
  { to: '/signaler', icon: FileText, labelKey: 'nav.report' },
  { to: '/suivi', icon: ClipboardList, labelKey: 'nav.tracking' },
  { to: '/chat', icon: MessageCircle, labelKey: 'nav.chat' },
  { to: '/ressources', icon: BookOpen, labelKey: 'nav.resources' },
  { to: '/annuaire', icon: MapPin, labelKey: 'nav.directory' },
  { to: '/observatoire', icon: BarChart3, labelKey: 'nav.observatory' },
];

const NAV_ITEMS_AUTH = [
  { to: '/dashboard', icon: LayoutDashboard, labelKey: 'nav.dashboard' },
  { to: '/signalements', icon: AlertTriangle, label: 'Signalements' },
  { to: '/conversations', icon: MessagesSquare, label: 'Conversations' },
  { to: '/profil', icon: User, label: 'Profil' },
];

export default function Layout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const { t, i18n } = useTranslation();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [sosOpen, setSosOpen] = useState(false);
  const [sosNumbers, setSosNumbers] = useState([]);
  const [darkMode, setDarkMode] = useState(() => localStorage.getItem('theme') === 'dark');

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', darkMode ? 'dark' : 'light');
    localStorage.setItem('theme', darkMode ? 'dark' : 'light');
  }, [darkMode]);

  useEffect(() => {
    api.get('/sos-numbers').then(r => setSosNumbers(r.data)).catch(() => {});
  }, []);

  const handleQuickExit = () => {
    window.location.replace('https://www.google.com');
  };

  const handleLogout = async () => {
    await logout();
    navigate('/');
  };

  const navItems = user ? NAV_ITEMS_AUTH : NAV_ITEMS_PUBLIC;

  const renderNavLink = (item) => {
    const Icon = item.icon;
    return (
      <NavLink
        key={item.to}
        to={item.to}
        end={item.end}
        className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
        onClick={() => setMobileOpen(false)}
      >
        <Icon size={16} />
        <span>{item.labelKey ? t(item.labelKey) : item.label}</span>
      </NavLink>
    );
  };

  return (
    <>
      <a href="#main-content" className="skip-link">Aller au contenu principal</a>

      <nav className="navbar" role="navigation" aria-label="Navigation principale">
        <NavLink to="/" className="nav-logo" onClick={() => setMobileOpen(false)}>
          <MaraLogo size="sm" showLabel />
        </NavLink>

        {/* Desktop nav — public tabs OR admin tabs, not both */}
        <div className="nav-links">
          {navItems.map(renderNavLink)}
        </div>

        <div className="nav-right">
          <div className="nav-lang">
            <Globe size={15} />
            <select
              value={i18n.language}
              onChange={e => i18n.changeLanguage(e.target.value)}
            >
              {LANGUAGES.map(l => (
                <option key={l.code} value={l.code}>{l.label}</option>
              ))}
            </select>
          </div>
          <button onClick={() => setDarkMode(d => !d)}
            style={{ background: 'none', border: '1px solid var(--border)', borderRadius: 8, padding: '5px 8px', cursor: 'pointer', color: 'var(--text-light)', display: 'flex', alignItems: 'center' }}
            aria-label={darkMode ? 'Mode clair' : 'Mode sombre'}>
            {darkMode ? <Sun size={16} /> : <Moon size={16} />}
          </button>
          {user ? (
            <>
              <span className="nav-user">
                <User size={14} /> {user.name}
              </span>
              <button className="btn btn-outline btn-sm" onClick={handleLogout}>
                <LogOut size={14} /> {t('nav.logout')}
              </button>
            </>
          ) : (
            <NavLink to="/login" className="btn btn-primary btn-sm">
              {t('nav.login')}
            </NavLink>
          )}

          {/* Mobile hamburger */}
          <button className="nav-hamburger" onClick={() => setMobileOpen(o => !o)} aria-label="Menu">
            {mobileOpen ? <X size={22} /> : <Menu size={22} />}
          </button>
        </div>
      </nav>

      {/* Mobile drawer */}
      {mobileOpen && <div className="nav-overlay" onClick={() => setMobileOpen(false)} />}
      <div className={`nav-drawer ${mobileOpen ? 'open' : ''}`}>
        <div className="nav-drawer-links">
          {navItems.map(renderNavLink)}
        </div>
        <div className="nav-drawer-footer">
          {user ? (
            <button className="btn btn-outline" style={{ width: '100%' }} onClick={() => { handleLogout(); setMobileOpen(false); }}>
              <LogOut size={16} /> {t('nav.logout')}
            </button>
          ) : (
            <NavLink to="/login" className="btn btn-primary" style={{ width: '100%' }} onClick={() => setMobileOpen(false)}>
              {t('nav.login')}
            </NavLink>
          )}
        </div>
      </div>

      <main id="main-content" className="main-content">
        <Outlet />
      </main>

      {/* Floating TTS Button */}
      <TextToSpeech />

      {/* Floating SOS Button */}
      <div style={{ position: 'fixed', bottom: 24, right: 24, zIndex: 900 }}>
        {sosOpen && (
          <div style={{
            position: 'absolute', bottom: 64, right: 0, background: 'white',
            borderRadius: 16, boxShadow: '0 8px 32px rgba(0,0,0,0.18)', padding: 16,
            width: 280, maxHeight: '60vh', overflow: 'auto'
          }}>
            <div style={{ fontWeight: 700, fontSize: 14, marginBottom: 12, color: '#D32F2F', display: 'flex', alignItems: 'center', gap: 6 }}>
              <Phone size={16} /> Numéros d'urgence
            </div>
            {sosNumbers.map(n => (
              <a key={n.id} href={`tel:${n.number.replace(/\s/g, '')}`}
                style={{
                  display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px',
                  borderRadius: 10, textDecoration: 'none', color: 'var(--text)',
                  background: '#FFF5F5', marginBottom: 6, transition: 'background .15s'
                }}
                onMouseEnter={e => e.currentTarget.style.background = '#FFEBEE'}
                onMouseLeave={e => e.currentTarget.style.background = '#FFF5F5'}
              >
                <div style={{ width: 36, height: 36, borderRadius: '50%', background: '#FFCDD2', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                  <Phone size={16} color="#D32F2F" />
                </div>
                <div>
                  <div style={{ fontWeight: 600, fontSize: 13 }}>{n.label}</div>
                  <div style={{ fontWeight: 800, fontSize: 16, color: '#D32F2F' }}>{n.number}</div>
                </div>
              </a>
            ))}
            <Link to="/annuaire" onClick={() => setSosOpen(false)}
              style={{ display: 'block', textAlign: 'center', fontSize: 13, color: 'var(--purple)', marginTop: 8, textDecoration: 'none', fontWeight: 600 }}>
              Voir l'annuaire complet →
            </Link>
          </div>
        )}
        <button onClick={() => setSosOpen(o => !o)}
          style={{
            width: 56, height: 56, borderRadius: '50%',
            background: sosOpen ? '#B71C1C' : '#D32F2F',
            color: 'white', border: 'none', cursor: 'pointer',
            boxShadow: '0 4px 16px rgba(211,47,47,0.4)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            transition: 'transform .2s, background .2s',
            animation: sosOpen ? 'none' : 'sos-pulse 2s infinite'
          }}
          onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.1)'}
          onMouseLeave={e => e.currentTarget.style.transform = ''}
          aria-label="Numéros d'urgence"
        >
          {sosOpen ? <X size={24} /> : <Phone size={24} />}
        </button>
      </div>

      <footer className="footer">
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 12 }}>
          <MaraLogo size="md" />
        </div>
        <div style={{ fontSize: 20, fontWeight: 800 }}>MARA</div>
        <p>{t('footer.subtitle')}</p>
        <p style={{ marginTop: 16 }}>{t('footer.copyright', { year: new Date().getFullYear() })}</p>
      </footer>
    </>
  );
}
