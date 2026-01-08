import { app, HttpRequest, InvocationContext } from "@azure/functions";
import { AuthRequestSchema } from "./schemas";
import { HttpResponseWithJson } from "../../common/types";
import { findCustomerByDocument } from "./repositories/customer.repository";
import { generateToken } from "../../common/utils/jwt.util";
import { getRequestBody } from "../../common/utils/requestBody.util";
import { CustomException } from "../../common/utils/customException";

app.http("authClient", {
  methods: ["POST"],
  authLevel: "anonymous",
  handler: async (
    request: HttpRequest,
    context: InvocationContext
  ): Promise<HttpResponseWithJson> => {
    try {
      const { cpf } = await getRequestBody(request, AuthRequestSchema);

      const clientData = await findCustomerByDocument(cpf, context).catch(
        () => null
      );

      if (!clientData) {
        throw new CustomException({
          message: () => "Cliente não encontrado.",
          status: 400,
        });
      }

      const token = generateToken({
        sub: clientData.id,
        cpf,
        nome: clientData.name,
        role: "client",
      });

      return {
        status: 200,
        body: JSON.stringify({ accessToken: token }),
      };
    } catch (error) {
      if (error instanceof CustomException) {
        return error.response;
      }
      throw error;
    }
  },
});
