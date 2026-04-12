import { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import api from '../api';
import { CheckCircle, AlertTriangle, Copy, Search, Volume2, Mic } from 'lucide-react';
import DynamicIcon from '../components/DynamicIcon';
import VoiceRecorder from '../components/VoiceRecorder';
import { SpeakButton } from '../components/TextToSpeech';

const REGIONS = [
  'Boucle du Mouhoun', 'Cascades', 'Centre', 'Centre-Est', 'Centre-Nord',
  'Centre-Ouest', 'Centre-Sud', 'Est', 'Hauts-Bassins', 'Nord',
  'Plateau-Central', 'Sahel', 'Sud-Ouest',
];

export default function ReportPage() {
  const { t } = useTranslation();
  const STEPS = t('report.steps', { returnObjects: true });
  const [step, setStep] = useState(0);
  const [violenceTypes, setViolenceTypes] = useState([]);
  const [submitted, setSubmitted] = useState(false);
  const [reference, setReference] = useState('');
  const [error, setError] = useState('');
  const [fieldErrors, setFieldErrors] = useState({});
  const [loading, setLoading] = useState(false);
  const [copied, setCopied] = useState(false);
  const [voiceBlob, setVoiceBlob] = useState(null);
  const [voiceDuration, setVoiceDuration] = useState(0);
  const [form, setForm] = useState({
    reporter_type: 'victime',
    victim_gender: 'feminin',
    victim_age_range: '',
    perpetrator_relation: '',
    violence_type_ids: [],
    region: '',
    province: '',
    lieu_description: '',
    incident_date: '',
    description: '',
    victim_status: 'inconnu',
    contact_phone: '',
    contact_time_pref: '',
  });

  useEffect(() => {
    api.get('/violence-types').then(r => setViolenceTypes(r.data)).catch(() => { });
  }, []);

  const update = (field, value) => {
    setForm(prev => ({ ...prev, [field]: value }));
    setFieldErrors(prev => ({ ...prev, [field]: undefined }));
  };

  const toggleViolenceType = (id) => {
    setForm(prev => ({
      ...prev,
      violence_type_ids: prev.violence_type_ids.includes(id)
        ? prev.violence_type_ids.filter(v => v !== id)
        : [...prev.violence_type_ids, id],
    }));
    setFieldErrors(prev => ({ ...prev, violence_type_ids: undefined }));
  };

  // Validation par étape
  const validateStep = (s) => {
    const errs = {};
    if (s === 1) {
      if (form.violence_type_ids.length === 0) errs.violence_type_ids = t('report.violenceTypeError');
    }
    if (s === 2) {
      // Description text OR voice note must be provided
      const hasText = form.description && form.description.trim().length >= 10;
      const hasVoice = !!voiceBlob;
      if (!hasText && !hasVoice) errs.description = t('report.descriptionOrVoiceError');
    }
    setFieldErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const nextStep = () => {
    if (validateStep(step)) setStep(s => s + 1);
  };

  const handleSubmit = async () => {
    setError('');
    setLoading(true);
    try {
      let data;
      if (voiceBlob) {
        const fd = new FormData();
        Object.entries(form).forEach(([key, value]) => {
          if (key === 'violence_type_ids') {
            value.forEach(id => fd.append('violence_type_ids[]', id));
          } else {
            fd.append(key, value ?? '');
          }
        });
        const ext = voiceBlob.type.includes('mp4') ? 'mp4' : 'webm';
        fd.append('voice_note', voiceBlob, `voice_note.${ext}`);
        const res = await api.post('/reports', fd, {
          headers: { 'Content-Type': 'multipart/form-data' },
        });
        data = res.data;
      } else {
        const res = await api.post('/reports', form);
        data = res.data;
      }
      setReference(data.report.reference);
      setSubmitted(true);
    } catch (err) {
      if (err.response?.status === 422) {
        const serverErrors = err.response.data.errors || {};
        const flat = {};
        Object.entries(serverErrors).forEach(([k, v]) => { flat[k] = Array.isArray(v) ? v[0] : v; });
        setFieldErrors(flat);
        // Revenir à l'étape contenant l'erreur
        if (flat.violence_type_ids) setStep(1);
        else if (flat.description || flat.incident_date || flat.region) setStep(2);
        else if (flat.contact_phone) setStep(3);
      } else {
        setError(err.response?.data?.message || t('report.submitError'));
      }
    } finally {
      setLoading(false);
    }
  };

  const copyReference = () => {
    navigator.clipboard.writeText(reference);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  // Libellés pour le résumé
  const getViolenceLabels = () => violenceTypes.filter(v => form.violence_type_ids.includes(v.id)).map(v => v.label_fr);
  const reporterLabels = t('report.reporterLabels', { returnObjects: true });
  const genderLabels = t('report.genderLabels', { returnObjects: true });
  const statusLabels = t('report.statusLabels', { returnObjects: true });

  if (submitted) {
    return (
      <div className="section" style={{ textAlign: 'center', paddingTop: 80 }}>
        <CheckCircle size={64} color="var(--success)" />
        <h2 style={{ marginTop: 24, color: 'var(--success)' }}>{t('report.successTitle')}</h2>
        <p style={{ marginTop: 16, color: 'var(--text-light)' }}>{t('report.successRefLabel')}</p>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 12, marginTop: 8, background: 'var(--purple-xlight)', padding: '14px 24px', borderRadius: 12, border: '2px solid var(--purple)' }}>
          <strong style={{ color: 'var(--purple)', fontSize: 22, letterSpacing: 1 }}>{reference}</strong>
          <button onClick={copyReference} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 4 }} title="Copier">
            <Copy size={18} color="var(--purple)" />
          </button>
        </div>
        {copied && <p style={{ color: 'var(--success)', fontSize: 12, marginTop: 4 }}>{t('report.copied')}</p>}
        <p style={{ marginTop: 16, color: 'var(--text-light)', fontSize: 14, maxWidth: 450, marginInline: 'auto' }}>
          {t('report.successMsg')}
        </p>
        {form.victim_status === 'danger_immediat' && (
          <div style={{ marginTop: 20, background: '#fff3e0', border: '1px solid var(--orange)', borderRadius: 8, padding: 16, maxWidth: 450, marginInline: 'auto' }}>
            <AlertTriangle size={20} color="var(--orange)" style={{ marginBottom: 4 }} />
            <p style={{ color: 'var(--orange)', fontWeight: 600, fontSize: 14 }}>{t('report.urgentMsg')}</p>
            <p style={{ color: 'var(--text-light)', fontSize: 13, marginTop: 4 }}>{t('report.urgentCallMsg')}</p>
          </div>
        )}
        <div style={{ marginTop: 28, display: 'flex', gap: 12, justifyContent: 'center', flexWrap: 'wrap' }}>
          <Link to="/suivi" className="btn btn-primary" style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
            <Search size={16} /> {t('report.trackBtn')}
          </Link>
          <Link to="/" className="btn btn-outline">{t('report.backHome')}</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="section" style={{ maxWidth: 700 }}>
      <div className="section-title">
        <h2>{t('report.title')}</h2>
        <p>{t('report.subtitle')}</p>
      </div>

      {/* Stepper */}
      <div className="stepper">
        {STEPS.map((s, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div className={`stepper-step ${i === step ? 'active' : i < step ? 'done' : ''}`}>{i + 1}</div>
            {i < STEPS.length - 1 && <div className={`stepper-line ${i < step ? 'active' : ''}`} />}
          </div>
        ))}
      </div>
      <p style={{ textAlign: 'center', fontSize: 13, color: 'var(--text-light)', marginBottom: 20 }}>
        {t('report.stepOf', { current: step + 1, total: STEPS.length })} — <strong>{STEPS[step]}</strong>
        <SpeakButton text={STEPS[step]} size={14} style={{ marginLeft: 6 }} />
      </p>

      <div className="card">
        {error && <div style={{ background: '#ffebee', color: 'var(--danger)', padding: 12, borderRadius: 8, marginBottom: 16, fontSize: 13 }}>{error}</div>}

        {/* Step 0: Identity */}
        {step === 0 && (
          <>
            <div className="form-group">
              <label className="form-label">{t('report.youAre')} * <SpeakButton text={t('report.youAre')} size={14} /></label>
              <select className="form-select" value={form.reporter_type} onChange={e => update('reporter_type', e.target.value)}>
                <option value="victime">{t('report.victim')}</option>
                <option value="temoin">{t('report.witness')}</option>
                <option value="proche">{t('report.relative')}</option>
                <option value="professionnel">{t('report.professional')}</option>
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">{t('report.victimGender')} * <SpeakButton text={t('report.victimGender')} size={14} /></label>
              <select className="form-select" value={form.victim_gender} onChange={e => update('victim_gender', e.target.value)}>
                <option value="feminin">{t('report.female')}</option>
                <option value="masculin">{t('report.male')}</option>
                <option value="autre">{t('report.other')}</option>
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">{t('report.ageRange')}</label>
              <select className="form-select" value={form.victim_age_range} onChange={e => update('victim_age_range', e.target.value)}>
                <option value="">{t('report.select')}</option>
                <option value="0-5">0-5 ans</option>
                <option value="6-12">6-12 ans</option>
                <option value="13-17">13-17 ans</option>
                <option value="18-25">18-25 ans</option>
                <option value="26-35">26-35 ans</option>
                <option value="36-50">36-50 ans</option>
                <option value="50+">50+ ans</option>
              </select>
            </div>
          </>
        )}

        {/* Step 1: Violence type */}
        {step === 1 && (
          <>
            <label className="form-label">{t('report.violenceType')} * <SpeakButton text={t('report.violenceType')} size={14} /></label>
            {fieldErrors.violence_type_ids && <p style={{ color: 'var(--danger)', fontSize: 12, marginBottom: 8 }}>{fieldErrors.violence_type_ids}</p>}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: 8 }}>
              {violenceTypes.map(vt => (
                <div
                  key={vt.id}
                  onClick={() => toggleViolenceType(vt.id)}
                  style={{
                    padding: '10px 14px',
                    borderRadius: 8,
                    border: `2px solid ${form.violence_type_ids.includes(vt.id) ? 'var(--purple)' : 'var(--border)'}`,
                    background: form.violence_type_ids.includes(vt.id) ? 'var(--purple-xlight)' : 'white',
                    cursor: 'pointer',
                    fontSize: 13,
                    fontWeight: 500,
                    transition: 'all 0.2s',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 8,
                  }}
                >
                  <DynamicIcon name={vt.icon} size={16} color={form.violence_type_ids.includes(vt.id) ? 'var(--purple)' : 'var(--text-light)'} /> {vt.label_fr}
                </div>
              ))}
            </div>
            <div className="form-group" style={{ marginTop: 16 }}>
              <label className="form-label">{t('report.perpetratorRelation')}</label>
              <select className="form-select" value={form.perpetrator_relation} onChange={e => update('perpetrator_relation', e.target.value)}>
                <option value="">{t('report.select')}</option>
                <option value="conjoint">{t('report.spouse')}</option>
                <option value="ex_conjoint">{t('report.exSpouse')}</option>
                <option value="famille">{t('report.family')}</option>
                <option value="voisin">{t('report.neighbor')}</option>
                <option value="employeur">{t('report.employer')}</option>
                <option value="inconnu">{t('report.unknown')}</option>
                <option value="autre">{t('report.otherRelation')}</option>
              </select>
            </div>
          </>
        )}

        {/* Step 2: Details */}
        {step === 2 && (
          <>
            <div className="form-group">
              <label className="form-label">{t('report.region')}</label>
              <select className="form-select" value={form.region} onChange={e => update('region', e.target.value)}>
                <option value="">{t('report.select')}</option>
                {REGIONS.map(r => (
                  <option key={r} value={r}>{r}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">{t('report.incidentDate')}</label>
              <input type="date" className="form-input" max={new Date().toISOString().split('T')[0]} value={form.incident_date} onChange={e => update('incident_date', e.target.value)} />
              {fieldErrors.incident_date && <p style={{ color: 'var(--danger)', fontSize: 12, marginTop: 4 }}>{fieldErrors.incident_date}</p>}
            </div>
            <div className="form-group">
              <label className="form-label">{t('report.description')} * <SpeakButton text={t('report.descriptionPlaceholder')} size={14} /></label>
              <textarea className="form-textarea" rows={5} placeholder={t('report.descriptionPlaceholder')} value={form.description} onChange={e => update('description', e.target.value)} />
              {fieldErrors.description && <p style={{ color: 'var(--danger)', fontSize: 12, marginTop: 4 }}>{fieldErrors.description}</p>}
              <p style={{ fontSize: 11, color: 'var(--text-light)', marginTop: 4 }}>{form.description.length} / 5000 {t('report.characters')}</p>
            </div>
            <div className="form-group">
              <label className="form-label">{t('report.voiceLabel')}</label>
              <p style={{ fontSize: 12, color: 'var(--text-light)', marginBottom: 8 }}>{t('report.voiceHint')}</p>
              <VoiceRecorder
                t={t}
                existingBlob={voiceBlob}
                onRecorded={(blob, dur) => { setVoiceBlob(blob); setVoiceDuration(dur); }}
                onRemove={() => { setVoiceBlob(null); setVoiceDuration(0); }}
              />
            </div>
            <div className="form-group">
              <label className="form-label">{t('report.victimStatus')} <SpeakButton text={t('report.victimStatus')} size={14} /></label>
              <select className="form-select" value={form.victim_status} onChange={e => update('victim_status', e.target.value)}>
                <option value="inconnu">{t('report.statusUnknown')}</option>
                <option value="en_securite">{t('report.statusSafe')}</option>
                <option value="danger_immediat">{t('report.statusDanger')}</option>
                <option value="hospitalisee">{t('report.statusHospitalized')}</option>
                <option value="disparue">{t('report.statusMissing')}</option>
              </select>
              {form.victim_status === 'danger_immediat' && (
                <p style={{ color: 'var(--orange)', fontSize: 12, marginTop: 6, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 4 }}>
                  <AlertTriangle size={14} /> {t('report.dangerWarning')}
                </p>
              )}
            </div>
          </>
        )}

        {/* Step 3: Contact */}
        {step === 3 && (
          <>
            <p style={{ fontSize: 13, color: 'var(--text-light)', marginBottom: 16 }}>
              {t('report.contactOptional')} <SpeakButton text={t('report.contactOptional')} size={14} />
            </p>
            <div className="form-group">
              <label className="form-label">{t('report.phone')}</label>
              <input className="form-input" type="tel" placeholder="Ex: 70 00 00 00" value={form.contact_phone} onChange={e => update('contact_phone', e.target.value)} />
              {fieldErrors.contact_phone && <p style={{ color: 'var(--danger)', fontSize: 12, marginTop: 4 }}>{fieldErrors.contact_phone}</p>}
            </div>
            <div className="form-group">
              <label className="form-label">{t('report.contactTimePref')}</label>
              <select className="form-select" value={form.contact_time_pref} onChange={e => update('contact_time_pref', e.target.value)}>
                <option value="">{t('report.select')}</option>
                <option value="matin">{t('report.morning')}</option>
                <option value="apres_midi">{t('report.afternoon')}</option>
                <option value="soir">{t('report.evening')}</option>
              </select>
            </div>
          </>
        )}

        {/* Step 4: Confirmation (résumé) */}
        {step === 4 && (
          <>
            <h3 style={{ marginBottom: 16, color: 'var(--purple)' }}>{t('report.verify')}</h3>
            <div style={{ display: 'grid', gap: 12 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid var(--border)' }}>
                <span style={{ color: 'var(--text-light)', fontSize: 13 }}>{t('report.youAre')}</span>
                <strong style={{ fontSize: 13 }}>{reporterLabels[form.reporter_type]}</strong>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid var(--border)' }}>
                <span style={{ color: 'var(--text-light)', fontSize: 13 }}>{t('report.victimGender')}</span>
                <strong style={{ fontSize: 13 }}>{genderLabels[form.victim_gender]}</strong>
              </div>
              {form.victim_age_range && (
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid var(--border)' }}>
                  <span style={{ color: 'var(--text-light)', fontSize: 13 }}>{t('report.ageRange')}</span>
                  <strong style={{ fontSize: 13 }}>{form.victim_age_range} ans</strong>
                </div>
              )}
              <div style={{ padding: '8px 0', borderBottom: '1px solid var(--border)' }}>
                <span style={{ color: 'var(--text-light)', fontSize: 13 }}>{t('report.violenceType')}</span>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 6 }}>
                  {getViolenceLabels().map(l => (
                    <span key={l} className="badge badge-purple">{l}</span>
                  ))}
                </div>
              </div>
              {form.region && (
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid var(--border)' }}>
                  <span style={{ color: 'var(--text-light)', fontSize: 13 }}>{t('report.region')}</span>
                  <strong style={{ fontSize: 13 }}>{form.region}</strong>
                </div>
              )}
              {form.incident_date && (
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid var(--border)' }}>
                  <span style={{ color: 'var(--text-light)', fontSize: 13 }}>{t('report.incidentDate')}</span>
                  <strong style={{ fontSize: 13 }}>{new Date(form.incident_date).toLocaleDateString('fr-FR')}</strong>
                </div>
              )}
              <div style={{ padding: '8px 0', borderBottom: '1px solid var(--border)' }}>
                <span style={{ color: 'var(--text-light)', fontSize: 13 }}>{t('report.description')}</span>
                {form.description && <p style={{ fontSize: 13, marginTop: 4, lineHeight: 1.5 }}>{form.description}</p>}
                {voiceBlob && (
                  <p style={{ fontSize: 13, marginTop: 4, color: 'var(--purple)', fontWeight: 500, display: 'flex', alignItems: 'center', gap: 4 }}>
                    <Mic size={13} /> {t('report.voiceAttached')} ({Math.floor(voiceDuration / 60).toString().padStart(2, '0')}:{(voiceDuration % 60).toString().padStart(2, '0')})
                  </p>
                )}
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid var(--border)' }}>
                <span style={{ color: 'var(--text-light)', fontSize: 13 }}>{t('report.victimStatus')}</span>
                <strong style={{ fontSize: 13, color: form.victim_status === 'danger_immediat' ? 'var(--danger)' : undefined }}>
                  {statusLabels[form.victim_status]}
                </strong>
              </div>
              {form.contact_phone && (
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid var(--border)' }}>
                  <span style={{ color: 'var(--text-light)', fontSize: 13 }}>{t('report.phone')}</span>
                  <strong style={{ fontSize: 13 }}>{form.contact_phone}</strong>
                </div>
              )}
            </div>
          </>
        )}

        {/* Navigation */}
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 24 }}>
          {step > 0 && (
            <button className="btn btn-outline" onClick={() => setStep(s => s - 1)}>{t('report.prev')}</button>
          )}
          <div style={{ marginLeft: 'auto' }}>
            {step < STEPS.length - 1 ? (
              <button className="btn btn-primary" onClick={nextStep}>{t('report.next')}</button>
            ) : (
              <button className="btn btn-orange" onClick={handleSubmit} disabled={loading}>
                {loading ? t('report.sending') : t('report.confirmSend')}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
