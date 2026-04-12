import { useState, useEffect, useRef, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import api from '../api';
import { Send, MessageCircle, EyeOff, Lock, UserCheck, X, Mic, Square, Play, Pause, Trash2 } from 'lucide-react';
import MaraLogo from '../components/MaraLogo';
import IconBadge from '../components/IconBadge';

const POLL_INTERVAL = 3000;

export default function ChatPage() {
  const { t } = useTranslation();
  const [conversationId, setConversationId] = useState(null);
  const [sessionToken, setSessionToken] = useState(null);
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [closed, setClosed] = useState(false);
  const messagesEndRef = useRef(null);
  const lastMsgId = useRef(0);
  const pollRef = useRef(null);

  // Voice recording state
  const [recording, setRecording] = useState(false);
  const [recDuration, setRecDuration] = useState(0);
  const [voiceBlob, setVoiceBlob] = useState(null);
  const mediaRecorderRef = useRef(null);
  const chunksRef = useRef([]);
  const recTimerRef = useRef(null);
  const streamRef = useRef(null);
  const MAX_VOICE = 120; // 2 min max

  // Restore session from sessionStorage on mount
  useEffect(() => {
    const saved = sessionStorage.getItem('mara_chat');
    if (saved) {
      try {
        const { cid, token } = JSON.parse(saved);
        if (cid && token) {
          setConversationId(cid);
          setSessionToken(token);
        }
      } catch { /* ignore */ }
    }
  }, []);

  // Fetch all messages when restoring a session
  useEffect(() => {
    if (!conversationId || !sessionToken) return;

    const fetchAll = async () => {
      try {
        const { data } = await api.get(`/conversations/${conversationId}/messages?token=${sessionToken}`);
        setMessages(data);
        if (data.length > 0) lastMsgId.current = data[data.length - 1].id;
        // Check if conversation is closed
        const convRes = await api.get(`/conversations/${conversationId}?token=${sessionToken}`);
        if (convRes.data.status === 'fermee') setClosed(true);
      } catch {
        // Token invalid — clear session
        sessionStorage.removeItem('mara_chat');
        setConversationId(null);
        setSessionToken(null);
      }
    };
    fetchAll();
  }, [conversationId, sessionToken]);

  // Poll for new messages
  const poll = useCallback(async () => {
    if (!conversationId || !sessionToken) return;
    try {
      const { data } = await api.get(`/conversations/${conversationId}/messages?token=${sessionToken}&after=${lastMsgId.current}`);
      if (data.length > 0) {
        setMessages(prev => {
          const existingIds = new Set(prev.map(m => m.id));
          const newMsgs = data.filter(m => !existingIds.has(m.id));
          return newMsgs.length > 0 ? [...prev, ...newMsgs] : prev;
        });
        lastMsgId.current = data[data.length - 1].id;
        // Detect close message
        const lastMsg = data[data.length - 1];
        if (!lastMsg.is_from_visitor && lastMsg.body.includes('clôturée')) {
          setClosed(true);
        }
      }
    } catch { /* silent */ }
  }, [conversationId, sessionToken]);

  useEffect(() => {
    if (!conversationId || closed) return;
    pollRef.current = setInterval(poll, POLL_INTERVAL);
    return () => clearInterval(pollRef.current);
  }, [conversationId, closed, poll]);

  // Auto-scroll
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // --- Voice recording helpers ---
  const fmtTime = (sec) => `${Math.floor(sec / 60).toString().padStart(2, '0')}:${(sec % 60).toString().padStart(2, '0')}`;

  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      streamRef.current = stream;
      const mime = MediaRecorder.isTypeSupported('audio/webm;codecs=opus') ? 'audio/webm;codecs=opus'
        : MediaRecorder.isTypeSupported('audio/mp4') ? 'audio/mp4' : '';
      const rec = new MediaRecorder(stream, mime ? { mimeType: mime } : undefined);
      mediaRecorderRef.current = rec;
      chunksRef.current = [];
      rec.ondataavailable = e => { if (e.data.size > 0) chunksRef.current.push(e.data); };
      rec.onstop = () => {
        const blob = new Blob(chunksRef.current, { type: rec.mimeType || 'audio/webm' });
        setVoiceBlob(blob);
        stream.getTracks().forEach(tr => tr.stop());
        streamRef.current = null;
      };
      rec.start(1000);
      setRecording(true);
      setRecDuration(0);
      recTimerRef.current = setInterval(() => {
        setRecDuration(prev => {
          if (prev + 1 >= MAX_VOICE) { stopRecording(); return MAX_VOICE; }
          return prev + 1;
        });
      }, 1000);
    } catch {
      alert(t('chat.voiceMicError'));
    }
  };

  const stopRecording = () => {
    if (recTimerRef.current) { clearInterval(recTimerRef.current); recTimerRef.current = null; }
    if (mediaRecorderRef.current && mediaRecorderRef.current.state !== 'inactive') mediaRecorderRef.current.stop();
    setRecording(false);
  };

  const cancelVoice = () => {
    setVoiceBlob(null);
    setRecDuration(0);
  };

  const sendVoice = async () => {
    if (!voiceBlob || !conversationId || closed) return;
    const dur = recDuration;
    const blob = voiceBlob;
    setVoiceBlob(null);
    setRecDuration(0);

    const tempId = Date.now();
    setMessages(prev => [...prev, { id: tempId, body: '', is_from_visitor: true, created_at: new Date().toISOString(), audio_url: URL.createObjectURL(blob), audio_duration: dur, _pending: true }]);

    try {
      const fd = new FormData();
      fd.append('body', '');
      const ext = blob.type.includes('mp4') ? 'mp4' : 'webm';
      fd.append('audio', blob, `voice.${ext}`);
      fd.append('audio_duration', dur);
      const { data } = await api.post(`/conversations/${conversationId}/messages?token=${sessionToken}`, fd, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      setMessages(prev => prev.map(m => m.id === tempId ? data : m));
      lastMsgId.current = Math.max(lastMsgId.current, data.id);
    } catch {
      setMessages(prev => prev.map(m => m.id === tempId ? { ...m, _failed: true } : m));
    }
  };

  const startChat = async () => {
    setLoading(true);
    try {
      const { data } = await api.post('/conversations/anonymous', {});
      setConversationId(data.conversation_id);
      setSessionToken(data.session_token);
      sessionStorage.setItem('mara_chat', JSON.stringify({ cid: data.conversation_id, token: data.session_token }));
    } catch { /* ignore */ }
    setLoading(false);
  };

  const sendMessage = async (e) => {
    e.preventDefault();
    if (!input.trim() || !conversationId || closed) return;

    const body = input.trim();
    setInput('');

    // Optimistic add
    const tempId = Date.now();
    setMessages(prev => [...prev, { id: tempId, body, is_from_visitor: true, created_at: new Date().toISOString(), _pending: true }]);

    try {
      const { data } = await api.post(`/conversations/${conversationId}/messages?token=${sessionToken}`, { body });
      // Replace optimistic message with real one
      setMessages(prev => prev.map(m => m.id === tempId ? data : m));
      lastMsgId.current = Math.max(lastMsgId.current, data.id);
    } catch {
      // Mark as failed
      setMessages(prev => prev.map(m => m.id === tempId ? { ...m, _failed: true } : m));
    }
  };

  const endChat = () => {
    sessionStorage.removeItem('mara_chat');
    setConversationId(null);
    setSessionToken(null);
    setMessages([]);
    setClosed(false);
    lastMsgId.current = 0;
  };

  // Landing screen
  if (!conversationId) {
    return (
      <div className="section" style={{ textAlign: 'center', paddingTop: 80 }}>
        <MessageCircle size={64} color="var(--purple)" />
        <h2 style={{ marginTop: 24 }}>{t('chat.title')}</h2>
        <p style={{ color: 'var(--text-light)', marginTop: 8, maxWidth: 500, margin: '8px auto 32px' }}>
          {t('chat.subtitle')}
        </p>
        <button className="btn btn-primary" onClick={startChat} disabled={loading}>
          {loading ? t('chat.connecting') : t('chat.startBtn')}
        </button>
        <div style={{ marginTop: 48 }}>
          <div className="grid-3" style={{ maxWidth: 800, margin: '0 auto' }}>
            {[
              { icon: <EyeOff size={24} />, title: t('chat.anonymous'), desc: t('chat.anonymousDesc'), color: '#00897B', bg: '#E0F2F1' },
              { icon: <Lock size={24} />, title: t('chat.confidential'), desc: t('chat.confidentialDesc'), color: '#7B2FBE', bg: '#EDE0FA' },
              { icon: <UserCheck size={24} />, title: t('chat.trainedAdvisors'), desc: t('chat.trainedAdvisorsDesc'), color: '#E8541E', bg: '#FFF0E8' },
            ].map((f, i) => (
              <div key={i} className="card" style={{ textAlign: 'center' }}>
                <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 12 }}>
                  <IconBadge color={f.color} bg={f.bg} size="lg">{f.icon}</IconBadge>
                </div>
                <h4 style={{ fontSize: 15, fontWeight: 700, marginBottom: 8 }}>{f.title}</h4>
                <p style={{ fontSize: 13, color: 'var(--text-light)' }}>{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // Chat interface
  return (
    <div className="chat-container">
      <div style={{ padding: '12px 24px', background: 'white', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', gap: 12 }}>
        <MaraLogo size="xs" />
        <div>
          <span style={{ fontSize: 14, fontWeight: 600 }}>{t('chat.confidentialChat')}</span>
          <p style={{ fontSize: 11, color: 'var(--text-light)', margin: 0 }}>
            {closed ? t('chat.ended') : t('chat.advisorWillReply')}
          </p>
        </div>
        <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 8 }}>
          {!closed && <span className="badge badge-success">{t('chat.active')}</span>}
          {closed && <span className="badge" style={{ background: '#f5f5f5', color: 'var(--text-light)' }}>{t('chat.closed')}</span>}
          <button onClick={endChat} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 4 }} title={t('chat.leaveChat')}>
            <X size={18} color="var(--text-light)" />
          </button>
        </div>
      </div>

      <div className="chat-messages">
        {messages.map(msg => (
          <div key={msg.id} className={`chat-message ${msg.is_from_visitor ? 'visitor' : 'conseiller'}`}>
            {!msg.is_from_visitor && msg.sender?.name && (
              <p style={{ fontSize: 11, color: 'var(--purple)', fontWeight: 600, marginBottom: 4 }}>{msg.sender.name}</p>
            )}
            {msg.audio_url ? (
              <ChatAudioPlayer src={msg.audio_url} duration={msg.audio_duration} visitor={msg.is_from_visitor} />
            ) : (
              msg.body
            )}
            <span style={{ display: 'block', fontSize: 10, color: msg.is_from_visitor ? 'rgba(255,255,255,0.6)' : 'var(--text-light)', marginTop: 4 }}>
              {new Date(msg.created_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
              {msg._pending && ` • ${t('chat.sending')}`}
              {msg._failed && ` • ${t('chat.failed')}`}
            </span>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      {!closed ? (
        recording ? (
          /* Recording bar */
          <div style={{ padding: '12px 16px', background: '#ffebee', borderTop: '2px solid var(--danger)', display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 10, height: 10, borderRadius: '50%', background: 'var(--danger)', animation: 'pulse 1s infinite' }} />
            <span style={{ fontWeight: 600, color: 'var(--danger)', fontSize: 14, fontVariantNumeric: 'tabular-nums' }}>{fmtTime(recDuration)}</span>
            <div style={{ flex: 1 }} />
            <button type="button" onClick={stopRecording} className="btn" style={{ background: 'var(--danger)', color: '#fff', borderRadius: 30, padding: '8px 18px', display: 'flex', alignItems: 'center', gap: 6 }}>
              <Square size={14} /> {t('chat.voiceStop')}
            </button>
          </div>
        ) : voiceBlob ? (
          /* Voice preview bar */
          <div style={{ padding: '12px 16px', background: 'var(--purple-xlight)', borderTop: '2px solid var(--purple)', display: 'flex', alignItems: 'center', gap: 10 }}>
            <Mic size={18} color="var(--purple)" />
            <span style={{ fontSize: 13, color: 'var(--purple)', fontWeight: 600 }}>{t('chat.voiceReady')} ({fmtTime(recDuration)})</span>
            <div style={{ flex: 1 }} />
            <button type="button" onClick={cancelVoice} style={{ background: '#ffebee', color: 'var(--danger)', border: 'none', borderRadius: '50%', width: 34, height: 34, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
              <Trash2 size={14} />
            </button>
            <button type="button" onClick={sendVoice} className="btn btn-primary" style={{ borderRadius: 30, padding: '8px 20px', display: 'flex', alignItems: 'center', gap: 6 }}>
              <Send size={16} /> {t('chat.voiceSend')}
            </button>
          </div>
        ) : (
          /* Normal input bar */
          <form className="chat-input-bar" onSubmit={sendMessage}>
            <button type="button" onClick={startRecording} style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 8, color: 'var(--purple)', display: 'flex', alignItems: 'center' }} title={t('chat.voiceRecord')}>
              <Mic size={22} />
            </button>
            <input
              type="text"
              placeholder={t('chat.placeholder')}
              value={input}
              onChange={e => setInput(e.target.value)}
              autoFocus
            />
            <button className="btn btn-primary" type="submit" disabled={!input.trim()} style={{ borderRadius: 30, padding: '10px 20px' }}>
              <Send size={18} />
            </button>
          </form>
        )
      ) : (
        <div style={{ padding: 16, textAlign: 'center', background: '#f9f9f9', borderTop: '1px solid var(--border)' }}>
          <p style={{ fontSize: 13, color: 'var(--text-light)', marginBottom: 12 }}>{t('chat.endedMsg')}</p>
          <button className="btn btn-primary" onClick={endChat}>{t('chat.newChat')}</button>
        </div>
      )}
    </div>
  );
}

/* Inline audio player for chat messages */
function ChatAudioPlayer({ src, duration, visitor }) {
  const audioRef = useRef(null);
  const [playing, setPlaying] = useState(false);
  const [progress, setProgress] = useState(0);

  const toggle = () => {
    if (!audioRef.current) return;
    if (playing) { audioRef.current.pause(); setPlaying(false); }
    else { audioRef.current.play(); setPlaying(true); }
  };

  const fmtDur = (s) => s ? `${Math.floor(s / 60).toString().padStart(2, '0')}:${(s % 60).toString().padStart(2, '0')}` : '';

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, minWidth: 180 }}>
      <audio ref={audioRef} src={src}
        onTimeUpdate={() => audioRef.current?.duration && setProgress((audioRef.current.currentTime / audioRef.current.duration) * 100)}
        onEnded={() => { setPlaying(false); setProgress(0); }}
      />
      <button type="button" onClick={toggle} style={{
        width: 32, height: 32, borderRadius: '50%', border: 'none', cursor: 'pointer',
        background: visitor ? 'rgba(255,255,255,0.25)' : 'var(--purple)', color: '#fff',
        display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
      }}>
        {playing ? <Pause size={14} /> : <Play size={14} />}
      </button>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 2 }}>
        <div style={{ height: 4, borderRadius: 2, background: visitor ? 'rgba(255,255,255,0.3)' : 'var(--border)', overflow: 'hidden' }}>
          <div style={{ width: `${progress}%`, height: '100%', background: visitor ? '#fff' : 'var(--purple)', borderRadius: 2, transition: 'width 0.2s' }} />
        </div>
        {duration > 0 && <span style={{ fontSize: 10, opacity: 0.7, display: 'flex', alignItems: 'center', gap: 3 }}><Mic size={10} /> {fmtDur(duration)}</span>}
      </div>
    </div>
  );
}
