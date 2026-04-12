import { Link } from 'react-router-dom';
import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import api from '../api';
import { MessageCircle, FileText, BookOpen, Phone, Shield, Users, AlertTriangle, MapPin, HeartHandshake, Megaphone, PlayCircle, Hand, Search } from 'lucide-react';
import DynamicIcon from '../components/DynamicIcon';
import MaraLogo from '../components/MaraLogo';
import IconBadge from '../components/IconBadge';
import { SpeakButton } from '../components/TextToSpeech';

export default function HomePage() {
  const [sosNumbers, setSosNumbers] = useState([]);
  const [announcements, setAnnouncements] = useState([]);
  const { t } = useTranslation();

  useEffect(() => {
    api.get('/sos-numbers').then(r => setSosNumbers(r.data)).catch(() => { });
    api.get('/announcements').then(r => setAnnouncements(r.data)).catch(() => { });
  }, []);

  return (
    <>
      {/* SOS Marquee Bar */}
      {sosNumbers.length > 0 && (
        <div className="sos-bar">
          <span className="sos-bar__label"><Phone size={14} /> {t('home.emergency')}</span>
          <div className="marquee">
            <div className="marquee__inner">
              {sosNumbers.map(s => (
                <span key={s.id} className="marquee__item">
                  <DynamicIcon name={s.icon} size={14} color="#fff" /> {s.label}: <strong>{s.number}</strong>
                </span>
              ))}
              {/* Duplicate for seamless loop */}
              {sosNumbers.map(s => (
                <span key={`dup-${s.id}`} className="marquee__item" aria-hidden="true">
                  <DynamicIcon name={s.icon} size={14} color="#fff" /> {s.label}: <strong>{s.number}</strong>
                </span>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* News Ticker */}
      {announcements.length > 0 && (
        <div className="news-ticker">
          <span className="news-ticker__label"><Megaphone size={14} /> Actualités</span>
          <div className="marquee marquee--slow">
            <div className="marquee__inner">
              {announcements.map((a, i) => (
                <span key={a.id || i} className="marquee__item news-ticker__item">
                  {a.title}
                  {a.source && <em className="news-ticker__source">— {a.source}</em>}
                </span>
              ))}
              {announcements.map((a, i) => (
                <span key={`dup-${a.id || i}`} className="marquee__item news-ticker__item" aria-hidden="true">
                  {a.title}
                  {a.source && <em className="news-ticker__source">— {a.source}</em>}
                </span>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Hero */}
      <section className="hero">
        <div>
          <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 24 }}>
            <MaraLogo size="lg" />
          </div>
          <h1 dangerouslySetInnerHTML={{ __html: t('home.heroTitle') }} />
          <p>{t('home.heroDesc')}</p>
          <div style={{ display: 'flex', gap: 16, justifyContent: 'center', flexWrap: 'wrap' }}>
            <Link to="/signaler" className="btn btn-orange" style={{ padding: '14px 32px', fontSize: 16, display: 'flex', alignItems: 'center', gap: 10 }}>
              <FileText size={22} /> {t('home.reportBtn')}
            </Link>
            <Link to="/chat" className="btn" style={{ padding: '14px 32px', fontSize: 16, background: 'rgba(255,255,255,0.2)', color: 'white', display: 'flex', alignItems: 'center', gap: 10 }}>
              <MessageCircle size={22} /> {t('home.chatBtn')}
            </Link>
          </div>
          <div style={{ marginTop: 12, display: 'flex', justifyContent: 'center' }}>
            <SpeakButton text={t('home.heroDesc')} size={20} style={{ color: 'rgba(255,255,255,0.8)' }} />
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="section">
        <div className="section-title">
          <h2>{t('home.howHelp')}</h2>
          <p>{t('home.howHelpDesc')}</p>
        </div>
        <div className="grid-3">
          {[
            { icon: <FileText size={28} />, title: t('home.featureReport'), desc: t('home.featureReportDesc'), link: '/signaler', color: '#E8541E', bg: '#FFF0E8' },
            { icon: <MessageCircle size={28} />, title: t('home.featureChat'), desc: t('home.featureChatDesc'), link: '/chat', color: '#7B2FBE', bg: '#EDE0FA' },
            { icon: <BookOpen size={28} />, title: t('home.featureResources'), desc: t('home.featureResourcesDesc'), link: '/ressources', color: '#2196F3', bg: '#E3F2FD' },
            { icon: <MapPin size={28} />, title: t('home.featureDirectory'), desc: t('home.featureDirectoryDesc'), link: '/annuaire', color: '#00897B', bg: '#E0F2F1' },
            { icon: <HeartHandshake size={28} />, title: t('home.featurePro'), desc: t('home.featureProDesc'), link: '/login', color: '#E91E63', bg: '#FCE4EC' },
            { icon: <AlertTriangle size={28} />, title: t('home.featureEmergency'), desc: t('home.featureEmergencyDesc'), link: '/annuaire', color: '#E74C3C', bg: '#FFEBEE' },
          ].map((f, i) => (
            <Link to={f.link} key={i} className="card feature-card" style={{ textDecoration: 'none' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <IconBadge color={f.color} bg={f.bg} size="lg">{f.icon}</IconBadge>
              </div>
              <h3 style={{ fontSize: 16, fontWeight: 700, marginBottom: 6, marginTop: 16, display: 'flex', alignItems: 'center', gap: 6 }}>
                {f.title} <SpeakButton text={`${f.title}. ${f.desc}`} size={14} />
              </h3>
              <p style={{ fontSize: 13, color: 'var(--text-light)' }}>{f.desc}</p>
            </Link>
          ))}
        </div>
      </section>

      {/* Video Tutorials */}
      <section className="section" style={{ background: 'var(--bg)', padding: '48px 24px' }}>
        <div style={{ maxWidth: 1200, margin: '0 auto' }}>
          <div className="section-title">
            <h2 style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
              <PlayCircle size={28} color="var(--purple)" /> {t('home.tutorials')}
              <SpeakButton text={t('home.tutorialsDesc')} size={18} />
            </h2>
            <p>{t('home.tutorialsDesc')}</p>
          </div>
          <div className="grid-3">
            {[
              { icon: Hand, title: t('home.tutoReport'), desc: t('home.tutoReportDesc'), color: '#E8541E', bg: '#FFF0E8' },
              { icon: MessageCircle, title: t('home.tutoChat'), desc: t('home.tutoChatDesc'), color: '#7B2FBE', bg: '#EDE0FA' },
              { icon: Search, title: t('home.tutoTrack'), desc: t('home.tutoTrackDesc'), color: '#2196F3', bg: '#E3F2FD' },
            ].map((tuto, i) => (
              <div key={i} className="card" style={{ textAlign: 'center', padding: 24 }}>
                <div style={{ marginBottom: 12, display: 'flex', justifyContent: 'center' }}>
                  <div style={{ width: 72, height: 72, borderRadius: '50%', background: tuto.bg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <tuto.icon size={36} color={tuto.color} />
                  </div>
                </div>
                <div style={{
                  width: '100%', aspectRatio: '16/9', borderRadius: 12,
                  background: tuto.bg, display: 'flex', alignItems: 'center', justifyContent: 'center',
                  marginBottom: 16, cursor: 'pointer', border: `2px dashed ${tuto.color}33`,
                }}>
                  <PlayCircle size={48} color={tuto.color} style={{ opacity: 0.7 }} />
                </div>
                <h3 style={{ fontSize: 15, fontWeight: 700, marginBottom: 6, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}>
                  {tuto.title} <SpeakButton text={`${tuto.title}. ${tuto.desc}`} size={14} />
                </h3>
                <p style={{ fontSize: 12, color: 'var(--text-light)' }}>{tuto.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Stats */}
      <section style={{ background: 'linear-gradient(135deg, var(--purple-dark), var(--purple))', padding: '60px 24px', color: 'white' }}>
        <div style={{ maxWidth: 1200, margin: '0 auto' }}>
          <div className="section-title">
            <h2 style={{ color: 'white' }}>{t('home.impact')}</h2>
          </div>
          <div className="grid-4">
            {[
              { num: '2,847', label: t('home.statReports') },
              { num: '89%', label: t('home.statResolution') },
              { num: '1,234', label: t('home.statAccompanied') },
              { num: '13', label: t('home.statRegions') },
            ].map((s, i) => (
              <div key={i} style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 36, fontWeight: 900 }}>{s.num}</div>
                <div style={{ fontSize: 13, opacity: 0.8 }}>{s.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>
    </>
  );
}
