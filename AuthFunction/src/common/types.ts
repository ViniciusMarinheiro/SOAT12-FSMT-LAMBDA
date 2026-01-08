import { HttpResponse } from "@azure/functions";

export type HttpResponseWithJson =
  | HttpResponse
  | {
      status: number;
      body?: string;
    };
