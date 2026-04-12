import { Link } from 'react-router-dom';
import { Home, ArrowLeft, AlertTriangle } from 'lucide-react';
import { useTranslation } from 'react-i18next';

export default function NotFoundPage() {
  const { t } = useTranslation();

  return (
    <div className="min-h-[60vh] flex items-center justify-center px-4">
      <div className="text-center max-w-md">
        <div className="flex justify-center mb-6">
          <div className="w-20 h-20 rounded-full bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center">
            <AlertTriangle className="w-10 h-10 text-orange-500" />
          </div>
        </div>

        <h1 className="text-6xl font-bold text-purple-700 dark:text-purple-400 mb-2">404</h1>
        <h2 className="text-xl font-semibold text-gray-800 dark:text-white mb-4">
          {t('notFound.title', 'Page introuvable')}
        </h2>
        <p className="text-gray-600 dark:text-gray-400 mb-8">
          {t('notFound.message', 'La page que vous recherchez n\'existe pas ou a été déplacée.')}
        </p>

        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <Link
            to="/"
            className="inline-flex items-center justify-center gap-2 px-6 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors font-medium"
          >
            <Home className="w-4 h-4" />
            {t('notFound.home', 'Retour à l\'accueil')}
          </Link>
          <button
            onClick={() => window.history.back()}
            className="inline-flex items-center justify-center gap-2 px-6 py-3 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors font-medium"
          >
            <ArrowLeft className="w-4 h-4" />
            {t('notFound.back', 'Page précédente')}
          </button>
        </div>
      </div>
    </div>
  );
}
