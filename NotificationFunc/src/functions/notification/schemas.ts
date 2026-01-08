import { z } from "zod";

export const NotificationRequestSchema = z.object({
  recipient: z.string().email("Email inválido"),
  subject: z.string().min(1, "Assunto é obrigatório"),
  body: z.string().min(1, "Corpo do email é obrigatório"),
  attachments: z
    .array(
      z.object({
        filename: z.string(),
        path: z.string().optional(),
        content: z.string().optional(),
        contentType: z.string().optional(),
      })
    )
    .optional(),
  channel: z.enum(["email", "sms", "push"]).default("email"),
});
