/**
 * Reusable MARA logo component with proper sizing and gradient styling.
 * Sizes: 'xs' (32px), 'sm' (48px), 'md' (80px), 'lg' (140px)
 */
const sizeMap = {
  xs: 32,
  sm: 48,
  md: 80,
  lg: 140,
};

export default function MaraLogo({ size = 'sm', showLabel = false, className = '' }) {
  const px = sizeMap[size] || sizeMap.sm;
  const borderWidth = size === 'lg' ? 3 : size === 'md' ? 2 : 2;

  return (
    <div className={`mara-logo mara-logo--${size} ${className}`} style={{ display: 'inline-flex', alignItems: 'center', gap: size === 'xs' ? 8 : 12 }}>
      <div
        className="mara-logo__ring"
        style={{
          width: px,
          height: px,
          minWidth: px,
          borderRadius: size === 'sm' ? 14 : '50%',
          background: 'linear-gradient(135deg, #4A0E8F, #7B2FBE, #E8541E)',
          padding: borderWidth,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: size === 'lg'
            ? '0 8px 32px rgba(123,47,190,0.3)'
            : size === 'md'
              ? '0 4px 20px rgba(123,47,190,0.2)'
              : '0 2px 8px rgba(123,47,190,0.15)',
        }}
      >
        <img
          src="/logo-mara.jpeg"
          alt="MARA"
          style={{
            width: '100%',
            height: '100%',
            borderRadius: size === 'sm' ? 12 : '50%',
            objectFit: 'contain',
            background: '#fff',
            display: 'block',
          }}
        />
      </div>
      {showLabel && (
        <span
          style={{
            fontSize: size === 'lg' ? 28 : size === 'md' ? 22 : 20,
            fontWeight: 800,
            background: 'linear-gradient(135deg, #4A0E8F, #7B2FBE)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            letterSpacing: '-0.5px',
          }}
        >
          MARA
        </span>
      )}
    </div>
  );
}
