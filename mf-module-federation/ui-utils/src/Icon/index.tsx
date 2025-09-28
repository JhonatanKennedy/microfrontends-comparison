import { FaPlus } from "react-icons/fa";
import { IconBaseProps } from "interfaces";

type TIconProps = IconBaseProps & {
  name: "plus";
};

export default function Icon(props: TIconProps) {
  const icons = {
    plus: FaPlus,
  };

  const Component = icons[props.name];

  return Component ? <Component /> : null;
}
