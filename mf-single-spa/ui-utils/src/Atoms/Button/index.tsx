import React from "react";
import { colors } from "../../theme";

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "contained" | "outlined" | "text";
  color?: "primary" | "secondary";
};

export function Button({
  children,
  variant = "contained",
  color = "primary",
  className,
  ...props
}: ButtonProps) {
  const baseStyle: React.CSSProperties = {
    padding: "8px 16px",
    borderRadius: "8px",
    fontWeight: 600,
    cursor: "pointer",
    border: "none",
  };

  const styles: Record<string, React.CSSProperties> = {
    contained: {
      backgroundColor: color === "primary" ? colors.primary : colors.secondary,
      color: "#fff",
    },
    outlined: {
      backgroundColor: "transparent",
      border: `2px solid ${
        color === "primary" ? colors.primary : colors.secondary
      }`,
      color: color === "primary" ? colors.primary : colors.secondary,
    },
    text: {
      backgroundColor: "transparent",
      color: color === "primary" ? colors.primary : colors.secondary,
    },
  };

  return (
    <button
      className={className}
      style={{ ...baseStyle, ...styles[variant] }}
      {...props}
    >
      {children}
    </button>
  );
}
