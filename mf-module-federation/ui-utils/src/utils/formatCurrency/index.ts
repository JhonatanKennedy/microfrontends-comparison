export function formatCurrency(value: string | number): string {
  let num = typeof value === "string" ? parseFloat(value) : value;

  if (isNaN(num)) return "R$ 0,00";

  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
  }).format(num);
}
