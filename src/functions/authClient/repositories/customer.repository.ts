import { InvocationContext } from "@azure/functions";
import { ClientData } from "../types";
import { ClientDataSchema } from "../schemas";
import { executeQuery } from "../../../common/utils/database.util";

export async function findCustomerByDocument(
  documentNumber: string,
  context: InvocationContext
): Promise<ClientData | null> {
  const query =
    "SELECT id, name, document_number, email FROM customers WHERE document_number = $1";

  const rows = await executeQuery<ClientData>(query, [documentNumber], context);

  if (!rows[0]) {
    return null;
  }

  return ClientDataSchema.parse(rows[0]);
}
