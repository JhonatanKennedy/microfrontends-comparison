import { TBoxProps as TProps } from "interfaces";

type TBoxProps = TProps & {
  children?: React.ReactNode;
};

export default function Box({
  children,
  direction = "row",
  gap = 8,
  align = "stretch",
  justify = "flex-start",
  wrap = false,
  className = "",
  style,
}: TBoxProps) {
  const rootStyle: React.CSSProperties = {
    display: "flex",
    flexDirection: direction,
    alignItems: align,
    justifyContent: justify,
    flexWrap: wrap ? "wrap" : "nowrap",
    gap,
    ...style,
  };

  return (
    <div className={className} style={rootStyle}>
      {children}
    </div>
  );
}
