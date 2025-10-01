import { VariantTypography } from "./css-rules";

export type TTypographyProps = {
  variant?: VariantTypography;
  component?: keyof JSX.IntrinsicElements;
  children: React.ReactNode;
  className?: string;
  color?: "primary" | "secondary";
  style?: React.CSSProperties;
};
