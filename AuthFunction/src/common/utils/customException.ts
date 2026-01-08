import { HttpResponseWithJson } from "../types";

interface CustomExceptionOptions {
  message: string | (() => string);
  status?: number;
}

export class CustomException extends Error {
  public readonly status: number;
  public readonly response: HttpResponseWithJson;

  constructor(options: CustomExceptionOptions) {
    const message =
      typeof options.message === "function"
        ? options.message()
        : options.message;
    super(message);

    this.status = options.status || 400;
    this.response = {
      status: this.status,
      body: JSON.stringify({
        message,
        timestamp: new Date().toISOString(),
      }),
    };

    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, CustomException);
    }
  }
}
