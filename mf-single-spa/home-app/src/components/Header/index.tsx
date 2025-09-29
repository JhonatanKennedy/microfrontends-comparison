import { colors, Box } from "@single-spa/ui-utils";
import {
  ChangeEvent,
  ChangeEventHandler,
  InputHTMLAttributes,
  useState,
} from "react";

type THeaderProps = {
  onChangeName: (value: string) => void;
};

export function Header({ onChangeName }: THeaderProps) {
  const [value, setValue] = useState("");

  function handleChange(event: ChangeEvent<HTMLInputElement>) {
    setValue(event.target.value);
    onChangeName(event.target.value);
  }

  return (
    <Box
      justify="center"
      style={{
        backgroundColor: colors.primary,
        padding: "30px 0px",
        width: "100%",
      }}
    >
      <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
        <input
          id="name"
          type="text"
          value={value}
          placeholder="Digite o nome do prato"
          onChange={handleChange}
          style={{
            padding: "10px 14px",
            border: `1px solid ${colors.textSecondary}`,
            borderRadius: "8px",
            fontSize: "15px",
            outline: "none",
          }}
        />
      </div>
    </Box>
  );
}
