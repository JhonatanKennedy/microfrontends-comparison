import Button from "uiUtils/Button";
import Box from "uiUtils/Box";
import Icon from "uiUtils/Icon";

export default function Home() {
  return (
    <div>
      <Box gap={10} direction={"column"}>
        <Icon name={"plus"} />
        <Button />
        <Button />
      </Box>
    </div>
  );
}
