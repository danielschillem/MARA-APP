import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

import fr from './fr.json';
import en from './en.json';
import mos from './mos.json';
import dyu from './dyu.json';
import ff from './ff.json';

export const LANGUAGES = [
  { code: 'fr', label: 'Français' },
  { code: 'en', label: 'English' },
  { code: 'mos', label: 'Mooré' },
  { code: 'dyu', label: 'Dioula' },
  { code: 'ff', label: 'Fulfuldé' },
];

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: {
      fr: { translation: fr },
      en: { translation: en },
      mos: { translation: mos },
      dyu: { translation: dyu },
      ff: { translation: ff },
    },
    fallbackLng: 'fr',
    interpolation: { escapeValue: false },
    detection: {
      order: ['localStorage', 'navigator'],
      caches: ['localStorage'],
    },
  });

export default i18n;
