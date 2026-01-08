import { Client } from "pg";
import { InvocationContext } from "@azure/functions";
import { DB_CONNECTION_STRING } from "../config";
import { CustomException } from "./customException";

export async function executeQuery<T>(
  query: string,
  params: any[],
  context: InvocationContext
): Promise<T[]> {
  if (!DB_CONNECTION_STRING) {
    throw new CustomException({
      message: () => "Conexão com o banco de dados mal configurada",
      status: 500,
    });
  }

  const client = new Client({ connectionString: DB_CONNECTION_STRING });

  try {
    await client.connect();
    const res = await client.query(query, params);
    return res.rows as T[];
  } catch (err: unknown) {
    context.log("Erro ao consultar banco de dados:", err);
    throw new CustomException({
      message: () => "Erro ao consultar banco de dados",
      status: 500,
    });
  } finally {
    await client.end();
  }
}
