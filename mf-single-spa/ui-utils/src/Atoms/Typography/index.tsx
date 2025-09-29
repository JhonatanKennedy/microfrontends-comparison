import React from "react";
import { typography, colors } from "../../theme";

type Variant = "h1" | "h2" | "body" | "caption";

type Props = {
  variant?: Variant;
  component?: keyof JSX.IntrinsicElements;
  children: React.ReactNode;
  className?: string;
  color?: "primary" | "secondary";
  style?: React.CSSProperties;
};

export function Typography({
  variant = "body",
  component: Component = "p",
  children,
  style,
  className,
  color = "primary",
  ...rest
}: Props) {
  const t = typography[variant];
  const c = color === "secondary" ? colors.textSecondary : colors.textPrimary;

  return (
    <Component
      className={className}
      style={{
        margin: 0,
        fontWeight: t?.fontWeight,
        fontSize: t?.fontSize,
        color: c,
        ...style,
      }}
      {...rest}
    >
      {children}
    </Component>
  );
}
