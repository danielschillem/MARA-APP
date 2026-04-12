/**
 * Styled icon badge with colored background circle/rounded shape.
 * Provides a consistent, polished look for business/domain icons.
 *
 * variant: 'circle' | 'rounded' (default: 'circle')
 * size: 'sm' (36px) | 'md' (48px) | 'lg' (64px)
 */
export default function IconBadge({ children, color = 'var(--purple)', bg, size = 'md', variant = 'circle', className = '' }) {
  const sizes = { sm: 36, md: 48, lg: 64 };
  const iconSizes = { sm: 18, md: 22, lg: 30 };
  const px = sizes[size] || sizes.md;

  // Auto-generate a light background from the color if not explicitly provided
  const defaultBg = bg || `color-mix(in srgb, ${color} 12%, white)`;

  return (
    <div
      className={`icon-badge icon-badge--${size} ${className}`}
      style={{
        width: px,
        height: px,
        minWidth: px,
        borderRadius: variant === 'rounded' ? px * 0.28 : '50%',
        background: defaultBg,
        color: color,
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        transition: 'transform 0.2s ease, box-shadow 0.2s ease',
      }}
    >
      {children}
    </div>
  );
}

/** Pre-configured color palettes for common business domains */
export const ICON_COLORS = {
  purple:  { color: '#7B2FBE', bg: '#EDE0FA' },
  orange:  { color: '#E8541E', bg: '#FFF0E8' },
  blue:    { color: '#2196F3', bg: '#E3F2FD' },
  green:   { color: '#27AE60', bg: '#E8F5E9' },
  red:     { color: '#E74C3C', bg: '#FFEBEE' },
  amber:   { color: '#F39C12', bg: '#FFF8E1' },
  teal:    { color: '#00897B', bg: '#E0F2F1' },
  pink:    { color: '#E91E63', bg: '#FCE4EC' },
  indigo:  { color: '#3F51B5', bg: '#E8EAF6' },
  cyan:    { color: '#0097A7', bg: '#E0F7FA' },
};
