export function convertToPercentage(
  value: string | number,
  fraction = true
): string {
  let num = typeof value === "string" ? parseFloat(value) : value;

  if (isNaN(num)) return "0%";

  if (fraction && num <= 1) {
    num = num * 100;
  }

  return `${num}%`;
}
