type Kind = 'success' | 'danger' | 'warning' | 'neutral';

export default function StatusDot({ kind, label }: { kind: Kind; label: string }) {
  return (
    <span className={`status ${kind}`}>
      <span className="dot" />
      {label}
    </span>
  );
}
