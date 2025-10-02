import { typography, colors } from "../../theme";
import { TTypographyProps } from "mf-tgc-types";

export function Typography({
  variant = "body",
  component: Component = "p",
  children,
  style,
  className,
  color = "primary",
  ...rest
}: TTypographyProps) {
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
