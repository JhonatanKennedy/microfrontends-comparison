import { ButtonHTMLAttributes, CSSProperties } from "react";
import { FaPlus, FaMinus, FaShoppingCart } from "react-icons/fa";
import { colors } from "../../theme";

const iconMap = {
  plus: FaPlus,
  minus: FaMinus,
  cart: FaShoppingCart,
};

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary" | "outlined";
  icon?: keyof typeof iconMap;
  iconPosition?: "start" | "end";
  hide?: boolean;
};

export function IconButton({
  children,
  variant = "primary",
  icon,
  iconPosition = "start",
  style,
  hide,
  ...props
}: ButtonProps) {
  if (hide) return null;

  const IconComponent = icon ? iconMap[icon] : null;

  const baseStyle: CSSProperties = {
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    gap: "8px",
    padding: "8px 16px",
    borderRadius: "8px",
    fontWeight: 600,
    cursor: "pointer",
    border: "none",
    ...(!children && {
      width: "30px",
      height: "30px",
      borderRadius: "50%",
      padding: 0,
    }),
  };

  const variantStyles: Record<string, CSSProperties> = {
    primary: { background: colors.primary, color: "#fff" },
    secondary: { background: colors.accent, color: "#fff" },
    outlined: {
      background: "transparent",
      border: `1px solid ${colors.primary}`,
      color: colors.primary,
    },
  };

  return (
    <button
      style={{
        ...baseStyle,
        ...variantStyles[variant],
        ...style,
      }}
      {...props}
    >
      {IconComponent && iconPosition === "start" && <IconComponent size={16} />}
      {children}
      {IconComponent && iconPosition === "end" && <IconComponent size={16} />}
    </button>
  );
}
