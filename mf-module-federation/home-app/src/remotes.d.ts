declare module "*.html" {
  const rawHtmlFile: string;
  export = rawHtmlFile;
}

declare module "*.bmp" {
  const src: string;
  export default src;
}

declare module "*.gif" {
  const src: string;
  export default src;
}

declare module "*.jpg" {
  const src: string;
  export default src;
}

declare module "*.jpeg" {
  const src: string;
  export default src;
}

declare module "*.png" {
  const src: string;
  export default src;
}

declare module "*.webp" {
  const src: string;
  export default src;
}

declare module "*.svg" {
  const src: string;
  export default src;
}

declare module "uiUtils" {
  import {
    TTypographyProps,
    TBoxProps,
    TButtonProps,
    TIconButtonProps,
    TInputProps,
    TConvertToPercentageFn,
    TFormatCurrencyFn,
    TNavigateOnButtonPressFn,
    TOrderStore,
    TColors,
  } from "mf-tgc-types";

  export const Typography: React.ComponentType<TTypographyProps>;
  export const Box: React.ComponentType<TBoxProps>;
  export const Button: React.ComponentType<TButtonProps>;
  export const IconButton: React.ComponentType<TIconButtonProps>;
  export const Input: React.ComponentType<TInputProps>;

  export const convertToPercentage: TConvertToPercentageFn;
  export const formatCurrency: TFormatCurrencyFn;
  export const navigateOnButtonPress: TNavigateOnButtonPressFn;

  export const colors: TColors;

  export const useStore: () => TOrderStore;
}
