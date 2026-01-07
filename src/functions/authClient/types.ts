import { z } from "zod";
import { AuthRequestSchema, ClientDataSchema } from "./schemas";

export type AuthRequest = z.infer<typeof AuthRequestSchema>;
export type ClientData = z.infer<typeof ClientDataSchema>;
