import { app, HttpRequest, InvocationContext } from "@azure/functions";
import { NotificationRequestSchema } from "./schemas";
import { HttpResponseWithJson } from "../../common/types";
import { getRequestBody } from "../../common/utils/requestBody.util";
import { CustomException } from "../../common/utils/customException";
import { NotificationService } from "./services/notification.service";

app.http("notification", {
  methods: ["POST"],
  authLevel: "anonymous",
  handler: async (
    request: HttpRequest,
    context: InvocationContext
  ): Promise<HttpResponseWithJson> => {
    try {
      const notificationData = await getRequestBody(
        request,
        NotificationRequestSchema
      );

      const notificationService = new NotificationService();
      await notificationService.send(notificationData, context);

      return {
        status: 200,
        body: JSON.stringify({
          message: "Notificação enviada com sucesso",
          channel: notificationData.channel,
        }),
      };
    } catch (error) {
      if (error instanceof CustomException) {
        return error.response;
      }

      context.log("Erro ao enviar notificação:", error);

      return {
        status: 500,
        body: JSON.stringify({
          message: "Erro ao enviar notificação",
          error: error instanceof Error ? error.message : "Erro desconhecido",
        }),
      };
    }
  },
});
