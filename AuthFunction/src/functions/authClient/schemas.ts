import { z } from "zod";
import { cpf as cpfValidator } from "cpf-cnpj-validator";

export const AuthRequestSchema = z.object({
  cpf: z
    .string()
    .min(1)
    .refine((cpf: string) => cpfValidator.isValid(cpf), "CPF inválido"),
});

export const ClientDataSchema = z.object({
  id: z.number(),
  name: z.string(),
  document_number: z.string(),
  email: z.string().optional(),
});
