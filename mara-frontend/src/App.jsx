import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { useCallback } from 'react';
import { AuthProvider } from './contexts/AuthContext';
import { ToastProvider, useToast } from './components/Toast';
import { useWsNotifications } from './hooks/useWsNotifications';
import Layout from './components/Layout';
import ProtectedRoute from './components/ProtectedRoute';
import HomePage from './pages/HomePage';
import ReportPage from './pages/ReportPage';
import ChatPage from './pages/ChatPage';
import DashboardPage from './pages/DashboardPage';
import ResourcesPage from './pages/ResourcesPage';
import DirectoryPage from './pages/DirectoryPage';
import TrackingPage from './pages/TrackingPage';
import CounselorChatPage from './pages/CounselorChatPage';
import ReportManagementPage from './pages/ReportManagementPage';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import ProfilePage from './pages/ProfilePage';
import ObservatoryPage from './pages/ObservatoryPage';
import NotFoundPage from './pages/NotFoundPage';
import AlertsPage from './pages/AlertsPage';
import TeamPage from './pages/TeamPage';
import AdminPage from './pages/AdminPage';

// ─── Real-time WS notifications ───────────────────────────────────────────────
const WS_MESSAGES = {
  new_report: { text: 'Nouveau signalement reçu', type: 'info' },
  report_updated: { text: 'Signalement mis à jour', type: 'success' },
  new_alert: { text: 'Nouvelle alerte citoyenne', type: 'warning' },
  alert_updated: { text: 'Alerte mise à jour', type: 'info' },
  new_message: { text: 'Nouveau message reçu', type: 'info' },
  conversation_closed: { text: 'Conversation clôturée', type: 'success' },
};

function WsNotifier() {
  const { addToast } = useToast();
  const handleEvent = useCallback((event) => {
    const meta = WS_MESSAGES[event.type];
    if (meta) addToast(meta.text, meta.type, 5000);
  }, [addToast]);
  useWsNotifications(handleEvent);
  return null;
}

export default function App() {
  return (
    <AuthProvider>
      <ToastProvider>
        <BrowserRouter>
          <WsNotifier />
          <Routes>
            <Route element={<Layout />}>
              {/* Public routes */}
              <Route path="/" element={<HomePage />} />
              <Route path="/signaler" element={<ReportPage />} />
              <Route path="/chat" element={<ChatPage />} />
              <Route path="/ressources" element={<ResourcesPage />} />
              <Route path="/annuaire" element={<DirectoryPage />} />
              <Route path="/observatoire" element={<ObservatoryPage />} />
              <Route path="/suivi" element={<TrackingPage />} />
              <Route path="/login" element={<LoginPage />} />
              <Route path="/register" element={<RegisterPage />} />

              {/* Protected routes */}
              <Route path="/dashboard" element={<ProtectedRoute><DashboardPage /></ProtectedRoute>} />
              <Route path="/conversations" element={<ProtectedRoute><CounselorChatPage /></ProtectedRoute>} />
              <Route path="/signalements" element={<ProtectedRoute><ReportManagementPage /></ProtectedRoute>} />
              <Route path="/alertes" element={<ProtectedRoute><AlertsPage /></ProtectedRoute>} />
              <Route path="/equipe" element={<ProtectedRoute><TeamPage /></ProtectedRoute>} />
              <Route path="/profil" element={<ProtectedRoute><ProfilePage /></ProtectedRoute>} />
              <Route path="/admin" element={<ProtectedRoute><AdminPage /></ProtectedRoute>} />

              {/* 404 */}
              <Route path="*" element={<NotFoundPage />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </ToastProvider>
    </AuthProvider>
  );
}
