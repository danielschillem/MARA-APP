import { useState, useEffect, useRef, useCallback } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import api from '../api';
import { MessageCircle, Send, Users, Clock, CheckCircle, X, UserPlus, AlertTriangle } from 'lucide-react';
import { buildWsUrl } from '../utils/ws';

const getWsUrl = (room = '') => buildWsUrl(room || undefined);

export default function CounselorChatPage() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [conversations, setConversations] = useState([]);
  const [activeConv, setActiveConv] = useState(null);
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [filter, setFilter] = useState('all');
  const messagesEndRef = useRef(null);
  const lastMsgId = useRef(0);
  const convWsRef = useRef(null);
  const listWsRef = useRef(null);
  const pollListRef = useRef(null);
  const fetchConvsRef = useRef(null);

  useEffect(() => {
    if (!user) navigate('/login');
  }, [user, navigate]);

  // Fetch conversation list
  const fetchConversations = useCallback(async () => {
    try {
      const params = filter === 'waiting' ? '?status=waiting' : filter === 'fermee' ? '?status=fermee' : '';
      const { data } = await api.get(`/conversations${params}`);
      setConversations(data);
    } catch { /* silent */ }
  }, [filter]);

  useEffect(() => {
    fetchConversations();
    pollListRef.current = setInterval(fetchConversations, 10000);
    return () => clearInterval(pollListRef.current);
  }, [fetchConversations]);

  // Select conversation
  const selectConv = async (conv) => {
    setActiveConv(conv);
    lastMsgId.current = 0;
    try {
      const { data } = await api.get(`/conversations/${conv.id}/messages`);
      setMessages(data);
      if (data.length > 0) lastMsgId.current = data[data.length - 1].id;
    } catch { /* silent */ }
  };

  // Garde fetchConversations à jour pour le handler WS
  useEffect(() => { fetchConvsRef.current = fetchConversations; }, [fetchConversations]);

  // WS liste — reçoit les événements conversation_activity
  useEffect(() => {
    const ws = new WebSocket(getWsUrl());
    ws.onmessage = (e) => {
      try {
        const ev = JSON.parse(e.data);
        if (ev.type === 'conversation_activity') fetchConvsRef.current?.();
      } catch { /* ignore */ }
    };
    ws.onerror = () => ws.close();
    listWsRef.current = ws;
    return () => { ws.close(); listWsRef.current = null; };
  }, []);

  // WS conversation active — reçoit les new_message en temps réel
  useEffect(() => {
    if (!activeConv?.id) return;
    convWsRef.current?.close();
    const ws = new WebSocket(getWsUrl(`conv:${activeConv.id}`));
    ws.onmessage = (e) => {
      try {
        const ev = JSON.parse(e.data);
        if (ev.type === 'new_message') {
          const msg = ev.payload;
          setMessages(prev => {
            if (prev.some(m => m.id === msg.id)) return prev;
            lastMsgId.current = Math.max(lastMsgId.current, msg.id ?? 0);
            return [...prev, msg];
          });
        }
      } catch { /* ignore */ }
    };
    ws.onerror = () => ws.close();
    convWsRef.current = ws;
    return () => { ws.close(); convWsRef.current = null; };
  }, [activeConv?.id]);

  // Auto-scroll
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const sendMessage = async (e) => {
    e.preventDefault();
    if (!input.trim() || !activeConv || activeConv.status === 'fermee') return;
    const body = input.trim();
    setInput('');

    const tempId = Date.now();
    setMessages(prev => [...prev, { id: tempId, body, is_from_visitor: false, sender: { name: user?.name }, created_at: new Date().toISOString(), _pending: true }]);

    try {
      const { data } = await api.post(`/conversations/${activeConv.id}/messages`, { body });
      // Remplace le message optimiste (WS peut l'avoir déjà ajouté)
      setMessages(prev => {
        const without = prev.filter(m => m.id !== tempId);
        return without.some(m => m.id === data.id) ? without : [...without, data];
      });
      lastMsgId.current = Math.max(lastMsgId.current, data.id);
      // Mise à jour immédiate de la liste
      fetchConversations();
    } catch {
      setMessages(prev => prev.map(m => m.id === tempId ? { ...m, _failed: true } : m));
    }
  };

  const assignToMe = async () => {
    if (!activeConv) return;
    try {
      await api.post(`/conversations/${activeConv.id}/assign`);
      setActiveConv(prev => ({ ...prev, conseiller_id: user?.id }));
      fetchConversations();
    } catch { /* silent */ }
  };

  const closeConv = async () => {
    if (!activeConv) return;
    try {
      await api.post(`/conversations/${activeConv.id}/close`);
      setActiveConv(prev => ({ ...prev, status: 'fermee' }));
      fetchConversations();
    } catch { /* silent */ }
  };

  if (!user) return null;

  const waitingCount = conversations.filter(c => !c.conseiller_id && c.status === 'active').length;

  return (
    <div className="section" style={{ padding: 0, maxWidth: 1200, margin: '0 auto' }}>
      <div style={{ display: 'flex', height: 'calc(100vh - 68px)' }}>
        {/* Sidebar — conversation list */}
        <div style={{ width: 340, borderRight: '1px solid var(--border)', display: 'flex', flexDirection: 'column', background: 'white' }}>
          <div style={{ padding: '16px', borderBottom: '1px solid var(--border)' }}>
            <h3 style={{ fontSize: 16, fontWeight: 700, marginBottom: 12, display: 'flex', alignItems: 'center', gap: 8 }}>
              <MessageCircle size={20} color="var(--purple)" />
              Conversations
              {waitingCount > 0 && <span className="badge badge-danger" style={{ fontSize: 11 }}>{waitingCount}</span>}
            </h3>
            <div style={{ display: 'flex', gap: 4 }}>
              {[
                { key: 'all', label: 'Toutes' },
                { key: 'waiting', label: 'En attente' },
                { key: 'fermee', label: 'Fermées' },
              ].map(f => (
                <button
                  key={f.key}
                  className={`nav-link ${filter === f.key ? 'active' : ''}`}
                  style={{ fontSize: 12, padding: '4px 10px' }}
                  onClick={() => setFilter(f.key)}
                >
                  {f.label}
                </button>
              ))}
            </div>
          </div>

          <div style={{ flex: 1, overflowY: 'auto' }}>
            {conversations.length === 0 ? (
              <p style={{ padding: 24, textAlign: 'center', color: 'var(--text-light)', fontSize: 13 }}>Aucune conversation</p>
            ) : conversations.map(conv => (
              <div
                key={conv.id}
                onClick={() => selectConv(conv)}
                style={{
                  padding: '12px 16px',
                  cursor: 'pointer',
                  borderBottom: '1px solid var(--border)',
                  background: activeConv?.id === conv.id ? 'var(--purple-xlight)' : 'white',
                  transition: 'background 0.15s',
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                  <span style={{ fontSize: 13, fontWeight: 600 }}>
                    Visiteur #{conv.id}
                  </span>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    {conv.unread_count > 0 && (
                      <span className="badge badge-danger" style={{ fontSize: 10, padding: '2px 6px', minWidth: 'auto' }}>
                        {conv.unread_count}
                      </span>
                    )}
                    {conv.status === 'fermee' ?
                      <CheckCircle size={14} color="var(--text-light)" /> :
                      !conv.conseiller_id ?
                        <Clock size={14} color="var(--warning)" /> :
                        <Users size={14} color="var(--success)" />
                    }
                  </div>
                </div>
                <p style={{ fontSize: 12, color: 'var(--text-light)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {conv.last_message_preview || 'Nouvelle conversation'}
                </p>
                <span style={{ fontSize: 10, color: 'var(--text-light)' }}>
                  {new Date(conv.updated_at || conv.created_at).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Main chat area */}
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
          {!activeConv ? (
            <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 12 }}>
              <MessageCircle size={48} color="var(--border)" />
              <p style={{ color: 'var(--text-light)' }}>Sélectionnez une conversation</p>
            </div>
          ) : (
            <>
              {/* Chat header */}
              <div style={{ padding: '12px 24px', background: 'white', borderBottom: '1px solid var(--border)', display: 'flex', alignItems: 'center', gap: 12 }}>
                <div>
                  <span style={{ fontSize: 14, fontWeight: 600 }}>Visiteur #{activeConv.id}</span>
                  <p style={{ fontSize: 11, color: 'var(--text-light)', margin: 0 }}>
                    {activeConv.status === 'fermee' ? 'Fermée' : activeConv.conseiller_id ? 'Assignée' : 'En attente'}
                    {' • '}{activeConv.messages_count || 0} messages
                  </p>
                </div>
                <div style={{ marginLeft: 'auto', display: 'flex', gap: 8 }}>
                  {!activeConv.conseiller_id && activeConv.status !== 'fermee' && (
                    <button className="btn btn-primary" onClick={assignToMe} style={{ fontSize: 12, padding: '6px 14px' }}>
                      <UserPlus size={14} style={{ marginRight: 4 }} /> Prendre en charge
                    </button>
                  )}
                  {activeConv.status !== 'fermee' && (
                    <button className="btn btn-outline" onClick={closeConv} style={{ fontSize: 12, padding: '6px 14px', color: 'var(--danger)', borderColor: 'var(--danger)' }}>
                      <X size={14} style={{ marginRight: 4 }} /> Clôturer
                    </button>
                  )}
                </div>
              </div>

              {/* Messages */}
              <div style={{ flex: 1, overflowY: 'auto', padding: 24, display: 'flex', flexDirection: 'column', gap: 12, background: 'var(--bg)' }}>
                {messages.map(msg => (
                  <div
                    key={msg.id}
                    style={{
                      maxWidth: '75%',
                      padding: '12px 16px',
                      borderRadius: 'var(--radius)',
                      fontSize: 14,
                      lineHeight: 1.5,
                      alignSelf: msg.is_from_visitor ? 'flex-start' : 'flex-end',
                      background: msg.is_from_visitor ? 'white' : 'var(--purple)',
                      color: msg.is_from_visitor ? 'var(--text)' : 'white',
                      border: msg.is_from_visitor ? '1px solid var(--border)' : 'none',
                      borderBottomLeftRadius: msg.is_from_visitor ? 4 : undefined,
                      borderBottomRightRadius: !msg.is_from_visitor ? 4 : undefined,
                    }}
                  >
                    {!msg.is_from_visitor && msg.sender?.name && (
                      <p style={{ fontSize: 11, fontWeight: 600, marginBottom: 4, opacity: 0.8 }}>{msg.sender.name}</p>
                    )}
                    {msg.body}
                    <span style={{ display: 'block', fontSize: 10, marginTop: 4, opacity: 0.6 }}>
                      {new Date(msg.created_at).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
                      {msg._pending && ' • envoi...'}
                      {msg._failed && <span style={{ display: 'inline-flex', alignItems: 'center', gap: 2 }}> • <AlertTriangle size={10} /> échec</span>}
                    </span>
                  </div>
                ))}
                <div ref={messagesEndRef} />
              </div>

              {/* Input */}
              {activeConv.status !== 'fermee' ? (
                <form onSubmit={sendMessage} style={{ padding: '16px 24px', background: 'white', borderTop: '1px solid var(--border)', display: 'flex', gap: 12 }}>
                  <input
                    type="text"
                    placeholder="Répondre au visiteur..."
                    value={input}
                    onChange={e => setInput(e.target.value)}
                    autoFocus
                    style={{ flex: 1, padding: '12px 16px', border: '2px solid var(--border)', borderRadius: 30, fontFamily: 'Poppins, sans-serif', fontSize: 14 }}
                  />
                  <button className="btn btn-primary" type="submit" disabled={!input.trim()} style={{ borderRadius: 30, padding: '10px 20px' }}>
                    <Send size={18} />
                  </button>
                </form>
              ) : (
                <div style={{ padding: 16, textAlign: 'center', background: '#f9f9f9', borderTop: '1px solid var(--border)' }}>
                  <p style={{ fontSize: 13, color: 'var(--text-light)' }}>Conversation clôturée</p>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
