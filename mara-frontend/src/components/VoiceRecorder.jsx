import { useState, useRef, useEffect } from 'react';
import { Mic, Square, Trash2, Play, Pause } from 'lucide-react';

export default function VoiceRecorder({ onRecorded, onRemove, existingBlob, t }) {
  const [recording, setRecording] = useState(false);
  const [paused, setPaused] = useState(false);
  const [duration, setDuration] = useState(0);
  const [audioUrl, setAudioUrl] = useState(null);
  const [playing, setPlaying] = useState(false);
  const [playProgress, setPlayProgress] = useState(0);

  const mediaRecorder = useRef(null);
  const chunks = useRef([]);
  const timerRef = useRef(null);
  const audioRef = useRef(null);
  const streamRef = useRef(null);

  const MAX_DURATION = 180; // 3 minutes max

  useEffect(() => {
    if (existingBlob) {
      setAudioUrl(URL.createObjectURL(existingBlob));
    }
  }, [existingBlob]);

  useEffect(() => {
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
      if (streamRef.current) {
        streamRef.current.getTracks().forEach(tr => tr.stop());
      }
      if (audioUrl) URL.revokeObjectURL(audioUrl);
    };
  }, [audioUrl]);

  const formatTime = (sec) => {
    const m = Math.floor(sec / 60).toString().padStart(2, '0');
    const s = Math.floor(sec % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  };

  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      streamRef.current = stream;

      const mimeType = MediaRecorder.isTypeSupported('audio/webm;codecs=opus')
        ? 'audio/webm;codecs=opus'
        : MediaRecorder.isTypeSupported('audio/mp4')
          ? 'audio/mp4'
          : '';

      const recorder = new MediaRecorder(stream, mimeType ? { mimeType } : undefined);
      mediaRecorder.current = recorder;
      chunks.current = [];

      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) chunks.current.push(e.data);
      };

      recorder.onstop = () => {
        const blob = new Blob(chunks.current, { type: recorder.mimeType || 'audio/webm' });
        const url = URL.createObjectURL(blob);
        setAudioUrl(url);
        onRecorded(blob, duration);
        stream.getTracks().forEach(tr => tr.stop());
        streamRef.current = null;
      };

      recorder.start(1000);
      setRecording(true);
      setPaused(false);
      setDuration(0);

      timerRef.current = setInterval(() => {
        setDuration(prev => {
          if (prev + 1 >= MAX_DURATION) {
            stopRecording();
            return MAX_DURATION;
          }
          return prev + 1;
        });
      }, 1000);
    } catch {
      alert(t('report.voiceMicError'));
    }
  };

  const stopRecording = () => {
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    if (mediaRecorder.current && mediaRecorder.current.state !== 'inactive') {
      mediaRecorder.current.stop();
    }
    setRecording(false);
    setPaused(false);
  };

  const removeRecording = () => {
    if (audioRef.current) audioRef.current.pause();
    if (audioUrl) URL.revokeObjectURL(audioUrl);
    setAudioUrl(null);
    setDuration(0);
    setPlaying(false);
    setPlayProgress(0);
    onRemove();
  };

  const togglePlayback = () => {
    if (!audioRef.current) return;
    if (playing) {
      audioRef.current.pause();
      setPlaying(false);
    } else {
      audioRef.current.play();
      setPlaying(true);
    }
  };

  const handleTimeUpdate = () => {
    if (audioRef.current && audioRef.current.duration) {
      setPlayProgress((audioRef.current.currentTime / audioRef.current.duration) * 100);
    }
  };

  const handleEnded = () => {
    setPlaying(false);
    setPlayProgress(0);
  };

  // Recording in progress
  if (recording) {
    return (
      <div style={{
        display: 'flex', alignItems: 'center', gap: 12,
        padding: '12px 16px', borderRadius: 12,
        background: '#ffebee', border: '2px solid var(--danger)',
      }}>
        <div style={{
          width: 12, height: 12, borderRadius: '50%',
          background: 'var(--danger)',
          animation: 'pulse 1s infinite',
        }} />
        <span style={{ fontWeight: 600, color: 'var(--danger)', fontSize: 14, fontVariantNumeric: 'tabular-nums' }}>
          {formatTime(duration)} / {formatTime(MAX_DURATION)}
        </span>
        <div style={{ flex: 1 }} />
        <button
          type="button"
          onClick={stopRecording}
          style={{
            display: 'flex', alignItems: 'center', gap: 6,
            padding: '8px 16px', borderRadius: 8,
            background: 'var(--danger)', color: '#fff',
            border: 'none', cursor: 'pointer', fontWeight: 600, fontSize: 13,
          }}
        >
          <Square size={14} /> {t('report.voiceStop')}
        </button>
      </div>
    );
  }

  // Recorded audio playback
  if (audioUrl) {
    return (
      <div style={{
        display: 'flex', alignItems: 'center', gap: 12,
        padding: '12px 16px', borderRadius: 12,
        background: 'var(--purple-xlight)', border: '2px solid var(--purple)',
      }}>
        <audio
          ref={audioRef}
          src={audioUrl}
          onTimeUpdate={handleTimeUpdate}
          onEnded={handleEnded}
        />
        <button
          type="button"
          onClick={togglePlayback}
          style={{
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            width: 36, height: 36, borderRadius: '50%',
            background: 'var(--purple)', color: '#fff',
            border: 'none', cursor: 'pointer',
          }}
        >
          {playing ? <Pause size={16} /> : <Play size={16} />}
        </button>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 4 }}>
          <div style={{
            height: 4, borderRadius: 2, background: 'var(--border)',
            overflow: 'hidden',
          }}>
            <div style={{
              width: `${playProgress}%`, height: '100%',
              background: 'var(--purple)', borderRadius: 2,
              transition: 'width 0.2s',
            }} />
          </div>
          <span style={{ fontSize: 11, color: 'var(--text-light)' }}>
            {t('report.voiceNote')} — {formatTime(duration)}
          </span>
        </div>
        <button
          type="button"
          onClick={removeRecording}
          title={t('report.voiceRemove')}
          style={{
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            width: 32, height: 32, borderRadius: '50%',
            background: '#ffebee', color: 'var(--danger)',
            border: 'none', cursor: 'pointer',
          }}
        >
          <Trash2 size={14} />
        </button>
      </div>
    );
  }

  // Default: start recording button
  return (
    <button
      type="button"
      onClick={startRecording}
      style={{
        display: 'flex', alignItems: 'center', gap: 8,
        padding: '10px 16px', borderRadius: 8,
        background: 'var(--purple-xlight)', color: 'var(--purple)',
        border: '2px dashed var(--purple)', cursor: 'pointer',
        fontWeight: 500, fontSize: 13, width: '100%',
      }}
    >
      <Mic size={18} /> {t('report.voiceRecord')}
    </button>
  );
}
