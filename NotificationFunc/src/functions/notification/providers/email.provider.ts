import { createTransport, Transporter } from "nodemailer";
import {
  SMTP_HOST,
  SMTP_PORT,
  SMTP_SECURE,
  SMTP_USER,
  SMTP_PASS,
} from "../../../common/config";
import { SendEmailData } from "../types";
import { CustomException } from "../../../common/utils/customException";

export class EmailProvider {
  private transporter: Transporter;

  constructor() {
    if (!SMTP_HOST || !SMTP_USER || !SMTP_PASS) {
      throw new CustomException({
        message: () => "Configurações de email não encontradas",
        status: 500,
      });
    }

    this.transporter = createTransport({
      host: SMTP_HOST,
      port: SMTP_PORT,
      secure: SMTP_SECURE,
      auth: {
        user: SMTP_USER,
        pass: SMTP_PASS,
      },
    });
  }

  async sendEmail(data: SendEmailData): Promise<void> {
    try {
      await this.transporter.sendMail({
        from: SMTP_USER,
        to: data.recipient,
        subject: data.subject,
        html: data.body,
        attachments: data.attachments,
      });
    } catch (error) {
      throw new CustomException({
        message: () => "Erro ao enviar email",
        status: 400,
      });
    }
  }
}
