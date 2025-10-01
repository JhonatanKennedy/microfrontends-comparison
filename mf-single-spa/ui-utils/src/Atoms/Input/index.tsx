import { colors } from "../../theme";
import { useState, ChangeEvent } from "react";

type TInputProps = {
  defaultValue?: string;
  name?: string;
  onChangeName: (value: string) => void;
  placeholder?: string;
};

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
