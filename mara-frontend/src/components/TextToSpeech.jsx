import { useState, useCallback, useRef, useEffect } from 'react';
import { Volume2, VolumeX } from 'lucide-react';
import { useTranslation } from 'react-i18next';

const LANG_MAP = {
  fr: 'fr-FR',
  en: 'en-US',
  mos: 'fr-FR', // fallback to French voice
  dyu: 'fr-FR',
  ff: 'fr-FR',
};

/**
 * Floating TTS button that reads the main content of the page aloud.
 * Uses the Web Speech API (SpeechSynthesis).
 */
export default function TextToSpeech() {
  const { t, i18n } = useTranslation();
  const [speaking, setSpeaking] = useState(false);
  const utteranceRef = useRef(null);

  useEffect(() => {
    return () => { window.speechSynthesis.cancel(); };
  }, []);

  const getPageText = useCallback(() => {
    const main = document.getElementById('main-content');
    if (!main) return '';
    // Collect visible text from headings, paragraphs, labels, buttons
    const selectors = 'h1, h2, h3, h4, p, label, .form-label, .btn, span, li, td, th';
    const elements = main.querySelectorAll(selectors);
    const seen = new Set();
    const texts = [];
    elements.forEach(el => {
      // Skip hidden elements and already processed parents
      if (el.offsetParent === null && el.style.display !== 'contents') return;
      const text = el.textContent?.trim();
      if (text && text.length > 1 && !seen.has(text)) {
        seen.add(text);
        texts.push(text);
      }
    });
    return texts.join('. ');
  }, []);

  const toggleSpeak = useCallback(() => {
    if (speaking) {
      window.speechSynthesis.cancel();
      setSpeaking(false);
      return;
    }

    const text = getPageText();
    if (!text) return;

    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = LANG_MAP[i18n.language] || 'fr-FR';
    utterance.rate = 0.9;
    utterance.pitch = 1;
    utterance.onend = () => setSpeaking(false);
    utterance.onerror = () => setSpeaking(false);
    utteranceRef.current = utterance;

    window.speechSynthesis.cancel();
    window.speechSynthesis.speak(utterance);
    setSpeaking(true);
  }, [speaking, getPageText, i18n.language]);

  // Don't render if speechSynthesis not supported
  if (typeof window === 'undefined' || !window.speechSynthesis) return null;

  return (
    <button
      onClick={toggleSpeak}
      title={speaking ? t('tts.stop') : t('tts.readPage')}
      aria-label={speaking ? t('tts.stop') : t('tts.readPage')}
      style={{
        position: 'fixed',
        bottom: 24,
        left: 24,
        zIndex: 900,
        width: 52,
        height: 52,
        borderRadius: '50%',
        background: speaking ? 'var(--orange)' : 'var(--purple)',
        color: '#fff',
        border: 'none',
        cursor: 'pointer',
        boxShadow: '0 4px 16px rgba(0,0,0,0.2)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        transition: 'transform .2s, background .2s',
        animation: speaking ? 'pulse 1.5s infinite' : 'none',
      }}
      onMouseEnter={e => e.currentTarget.style.transform = 'scale(1.1)'}
      onMouseLeave={e => e.currentTarget.style.transform = ''}
    >
      {speaking ? <VolumeX size={22} /> : <Volume2 size={22} />}
    </button>
  );
}

/**
 * Small inline button to read a specific text aloud.
 * Usage: <SpeakButton text="Some text to read" />
 */
export function SpeakButton({ text, size = 16, style = {} }) {
  const { i18n, t } = useTranslation();
  const [active, setActive] = useState(false);

  const speak = (e) => {
    e.preventDefault();
    e.stopPropagation();
    if (active) {
      window.speechSynthesis.cancel();
      setActive(false);
      return;
    }
    if (!text) return;
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = LANG_MAP[i18n.language] || 'fr-FR';
    utterance.rate = 0.9;
    utterance.onend = () => setActive(false);
    utterance.onerror = () => setActive(false);
    window.speechSynthesis.cancel();
    window.speechSynthesis.speak(utterance);
    setActive(true);
  };

  if (typeof window === 'undefined' || !window.speechSynthesis) return null;

  return (
    <button
      type="button"
      onClick={speak}
      title={active ? t('tts.stop') : t('tts.listen')}
      aria-label={active ? t('tts.stop') : t('tts.listen')}
      style={{
        background: 'none',
        border: 'none',
        cursor: 'pointer',
        padding: 2,
        color: active ? 'var(--orange)' : 'var(--purple)',
        display: 'inline-flex',
        alignItems: 'center',
        verticalAlign: 'middle',
        ...style,
      }}
    >
      {active ? <VolumeX size={size} /> : <Volume2 size={size} />}
    </button>
  );
}
