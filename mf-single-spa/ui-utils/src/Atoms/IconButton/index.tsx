import { CSSProperties } from "react";
import {
  FaPlus,
  FaMinus,
  FaShoppingCart,
  FaArrowLeft,
  FaRegTrashAlt,
} from "react-icons/fa";
import { colors } from "../../theme";
import { TIconButtonProps } from "mf-tgc-types";

const iconMap = {
  plus: FaPlus,
  minus: FaMinus,
  cart: FaShoppingCart,
  arrowLeft: FaArrowLeft,
  trash: FaRegTrashAlt,
};

export function IconButton({
  children,
  variant = "primary",
  icon,
  iconPosition = "start",
  style,
  hide,
  size = 16,
  ...props
}: TIconButtonProps) {
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
      {IconComponent && iconPosition === "start" && (
        <IconComponent size={size} />
      )}
      {children}
      {IconComponent && iconPosition === "end" && <IconComponent size={size} />}
    </button>
  );
}
