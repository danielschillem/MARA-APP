import {
  Hand, AlertTriangle, Brain, Wallet, Megaphone, Smartphone, ShieldOff, Lock, Scissors, Link2,
  PhoneCall, ShieldAlert, Ambulance, Flame, HandHelping,
  Shield, Heart, Building, Stethoscope, Scale, Siren,
  Phone, MapPin, Clock, FileText, Play, BookOpen, GraduationCap, MessageCircle, Users,
  HeartCrack, Baby, Frown, Handshake, UserX, Ban, CircleSlash, Eye, BriefcaseMedical,
  Gavel, Landmark, LifeBuoy, BadgeAlert, HeartPulse, Volume2,
  Newspaper, Video, ScrollText, FileCheck, BarChart3, Presentation
} from 'lucide-react';

const ICON_MAP = {
  // Violence types — more expressive icons
  'hand-fist': Hand,
  'alert-triangle': AlertTriangle,
  'brain': Brain,
  'wallet': Wallet,
  'megaphone': Megaphone,
  'smartphone': Smartphone,
  'shield-off': ShieldOff,
  'lock': Lock,
  'scissors': Scissors,
  'link-2': Link2,
  'heart-crack': HeartCrack,
  'baby': Baby,
  'frown': Frown,
  'handshake': Handshake,
  'user-x': UserX,
  'ban': Ban,
  'circle-slash': CircleSlash,
  'eye': Eye,
  // SOS numbers
  'phone-call': PhoneCall,
  'shield-alert': ShieldAlert,
  'ambulance': Ambulance,
  'flame': Flame,
  'hand-helping': HandHelping,
  'badge-alert': BadgeAlert,
  'heart-pulse': HeartPulse,
  'volume-2': Volume2,
  'life-buoy': LifeBuoy,
  // Service types
  'shield': Shield,
  'heart': Heart,
  'building': Building,
  'stethoscope': Stethoscope,
  'scale': Scale,
  'siren': Siren,
  'gavel': Gavel,
  'landmark': Landmark,
  'briefcase-medical': BriefcaseMedical,
  // Resources
  'phone': Phone,
  'map-pin': MapPin,
  'clock': Clock,
  'file-text': FileText,
  'play': Play,
  'book-open': BookOpen,
  'graduation-cap': GraduationCap,
  'message-circle': MessageCircle,
  'users': Users,
  'newspaper': Newspaper,
  'video': Video,
  'scroll-text': ScrollText,
  'file-check': FileCheck,
  'bar-chart-3': BarChart3,
  'presentation': Presentation,
};

export default function DynamicIcon({ name, size = 20, color, className, style }) {
  const IconComponent = ICON_MAP[name];
  if (!IconComponent) return null;
  return <IconComponent size={size} color={color} className={className} style={style} />;
}

export { ICON_MAP };
