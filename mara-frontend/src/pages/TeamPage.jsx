import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import api from '../api';
import { User, CheckCircle, AlertCircle, Clock, MapPin, UserPlus } from 'lucide-react';

const STATUS_COLORS = {
  active: { bg: '#EAF5EE', color: '#2D6A4F', label: 'Actif' },
  busy:   { bg: '#FDF5E8', color: '#B87A1A', label: 'Occupé' },
  off:    { bg: '#F5F5F0', color: '#999999', label: 'Absent' },
};

function deriveStatus(user) {
  if (user.is_online && (user.active_cases || 0) === 0) return 'active';
  if (user.is_online) return 'busy';
  return 'off';
}

export default function TeamPage() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [team, setTeam] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) { navigate('/login'); return; }
    api.get('/team')
      .then(r => setTeam(r.data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [user]);

  if (!user) return null;

  const active = team.filter(m => deriveStatus(m) !== 'off').length;

  return (
    <div className="section">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 24, fontWeight: 800 }}>Équipe de coordination</h2>
          <p style={{ color: 'var(--text-light)', fontSize: 14 }}>
            {team.length} coordinateur{team.length !== 1 ? 's' : ''} · {active} actif{active !== 1 ? 's' : ''} en ce moment
          </p>
        </div>
        <button className="btn btn-primary" style={{ gap: 6 }}>
          <UserPlus size={15} /> Ajouter
        </button>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: 60, color: 'var(--text-light)' }}>Chargement…</div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {team.map(member => {
            const st = STATUS_COLORS[deriveStatus(member)];
            return (
              <div key={member.id} className="card" style={{ padding: '16px 20px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                  {/* Avatar */}
                  <div style={{
                    width: 48, height: 48, borderRadius: '50%',
                    background: 'linear-gradient(135deg, #1A2E4A, #2A4870)',
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 16, fontWeight: 700, color: '#fff', flexShrink: 0,
                  }}>
                    {member.avatar || member.name.slice(0, 2).toUpperCase()}
                  </div>

                  {/* Info */}
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <span style={{ fontSize: 15, fontWeight: 700 }}>{member.name}</span>
                      <span style={{
                        padding: '2px 8px', borderRadius: 20, fontSize: 10, fontWeight: 700,
                        background: st.bg, color: st.color,
                      }}>
                        {st.label}
                      </span>
                    </div>
                    <div style={{ fontSize: 12, color: 'var(--text-light)', marginTop: 2 }}>
                      {member.titre || member.role}
                    </div>
                    {member.zone && (
                      <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: 'var(--text-light)', marginTop: 4 }}>
                        <MapPin size={10} /> {member.zone}
                      </div>
                    )}
                  </div>

                  {/* Stats */}
                  <div style={{ display: 'flex', gap: 16, textAlign: 'center' }}>
                    <div>
                      <div style={{ fontSize: 20, fontWeight: 800, color: '#B87A1A', fontFamily: 'var(--font-heading)' }}>
                        {member.active_cases ?? 0}
                      </div>
                      <div style={{ fontSize: 10, color: 'var(--text-light)' }}>En cours</div>
                    </div>
                    <div>
                      <div style={{ fontSize: 20, fontWeight: 800, color: '#2D6A4F', fontFamily: 'var(--font-heading)' }}>
                        {member.resolved_cases ?? 0}
                      </div>
                      <div style={{ fontSize: 10, color: 'var(--text-light)' }}>Résolus</div>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
