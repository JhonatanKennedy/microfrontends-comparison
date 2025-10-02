type ProductGridProps = {
  children: React.ReactNode;
};

export function Container({ children }: ProductGridProps) {
  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(auto-fill, minmax(160px, 1fr))",
        gap: "16px",
        padding: "16px",
      }}
    >
      {children}
    </div>
  );
}
