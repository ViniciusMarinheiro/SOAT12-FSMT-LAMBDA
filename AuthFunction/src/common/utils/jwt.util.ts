import jwt from "jsonwebtoken";
import { JWT_SECRET } from "../config";

interface TokenPayload {
  sub: number | null;
  cpf: string;
  nome: string;
  role: string;
}

export function generateToken(payload: TokenPayload): string {
  return jwt.sign(payload, JWT_SECRET, {
    algorithm: "HS256",
    expiresIn: "1h",
  });
}
