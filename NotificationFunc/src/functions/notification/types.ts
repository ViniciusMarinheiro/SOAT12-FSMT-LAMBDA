import { z } from "zod";
import { NotificationRequestSchema } from "./schemas";

export type NotificationRequest = z.infer<typeof NotificationRequestSchema>;

export interface SendEmailData {
  recipient: string;
  subject: string;
  body: string;
  attachments?: Array<{
    filename: string;
    path?: string;
    content?: string;
    contentType?: string;
  }>;
}
