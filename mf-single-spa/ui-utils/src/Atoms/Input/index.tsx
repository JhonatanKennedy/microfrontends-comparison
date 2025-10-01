import { TInputProps } from "mf-tgc-types";
import { colors } from "../../theme";
import { useState, ChangeEvent } from "react";

export function Input({
  placeholder,
  name,
  defaultValue,
  onChangeName,
}: TInputProps) {
  const [value, setValue] = useState(defaultValue ?? "");

  function handleChange(event: ChangeEvent<HTMLInputElement>) {
    setValue(event.target.value);
    onChangeName(event.target.value);
  }

  return (
    <input
      name={name}
      type="text"
      value={value}
      placeholder={placeholder}
      onChange={handleChange}
      style={{
        padding: "10px 14px",
        border: "1px solid",
        borderColor: colors.textSecondary,
        borderRadius: "8px",
        fontSize: "15px",
        outline: "none",
      }}
    />
  );
}
