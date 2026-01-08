import { HttpRequest } from "@azure/functions";
import { z } from "zod";
import { CustomException } from "./customException";

export const getRequestBody = async <T extends z.ZodTypeAny>(
  request: HttpRequest,
  schema?: T
): Promise<z.infer<T>> => {
  if (!request.body) {
    throw new CustomException({
      message: () => "Corpo da requisição é obrigatório",
      status: 400,
    });
  }

  const body = await request.json();

  if (schema) {
    const result = schema.safeParse(body);
    if (!result.success) {
      throw new CustomException({
        message: () => "Dados inválidos",
        status: 400,
      });
    }
    return result.data;
  }

  return body;
};
