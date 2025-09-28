import { FaPlus } from "react-icons/fa";
import { IconBaseProps, IconType } from "interfaces";

type TIconProps = IconBaseProps & {
  name: "plus";
};

export function Icon(props: TIconProps) {
  const { name, ...rest } = props;

  const icons = {
    plus: FaPlus,
  };

  const Component = icons[name] as React.ComponentType<any>;

  return Component ? <Component {...rest} /> : null;
}
