import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { ToastProvider } from './components/Toast';
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

export default function App() {
  return (
    <AuthProvider>
      <ToastProvider>
        <BrowserRouter>
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
              <Route path="/profil" element={<ProtectedRoute><ProfilePage /></ProtectedRoute>} />

              {/* 404 */}
              <Route path="*" element={<NotFoundPage />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </ToastProvider>
    </AuthProvider>
  );
}
