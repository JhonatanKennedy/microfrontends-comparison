declare module "uiUtils/Button";
declare module "uiUtils/Icon" {
  import { IconType } from "interfaces";

  const Icons: IconType;
  export default Icons;
}

declare module "uiUtils/Box" {
  import { TBoxProps } from "interfaces";

  const Box: React.ComponentType<TBoxProps>;
  export default Box;
}
