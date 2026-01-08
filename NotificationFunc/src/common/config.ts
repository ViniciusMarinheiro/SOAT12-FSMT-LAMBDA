export const JWT_SECRET =
  process.env.JWT_SECRET || "minha-chave-super-secreta-padrao";

export const DB_CONNECTION_STRING = process.env.DB_CONNECTION_STRING;

export const SMTP_HOST = process.env.SMTP_HOST;
export const SMTP_PORT = Number(process.env.PORT_EMAIL) || 587;
export const SMTP_SECURE = process.env.SECURE_EMAIL === "true";
export const SMTP_USER = process.env.USER_EMAIL;
export const SMTP_PASS = process.env.PASS_EMAIL;
