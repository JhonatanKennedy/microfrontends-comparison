import { Icon, Button } from "@single-spa/ui-utils";

export default function Root(props) {
  return (
    <section>
      {props.name} is mounted!
      <div>
        <Icon name={"plus"} />
        <Button />
      </div>
    </section>
  );
}
