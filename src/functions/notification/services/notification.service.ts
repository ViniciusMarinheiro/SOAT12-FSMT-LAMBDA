import { InvocationContext } from "@azure/functions";
import { NotificationRequest } from "../types";
import { EmailProvider } from "../providers/email.provider";
import { CustomException } from "../../../common/utils/customException";

export class NotificationService {
  private emailProvider: EmailProvider;

  constructor() {
    this.emailProvider = new EmailProvider();
  }

  async send(
    notification: NotificationRequest,
    context: InvocationContext
  ): Promise<void> {
    context.log(`Enviando notificação para: ${notification.recipient}`);

    switch (notification.channel) {
      case "email":
        await this.emailProvider.sendEmail(notification);
        break;
      case "sms":
        throw new CustomException({
          message: () => "SMS ainda não implementado",
          status: 500,
        });
      case "push":
        // TODO: Implementar Push notification provider
        throw new CustomException({
          message: () => "Push notification ainda não implementado",
          status: 500,
        });
      default:
        throw new CustomException({
          message: () =>
            `Canal de notificação inválido: ${notification.channel}`,
          status: 400,
        });
    }
  }
}
