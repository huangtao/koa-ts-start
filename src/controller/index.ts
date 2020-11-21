import { Context } from 'koa';

export const get = async (ctx: Context) => {
  ctx.body = 'Koa2 run on typescript.';
}

// export const sms = async (ctx: Context, next: any) => {
//   if (typeof ctx.query.phone === 'undefined') {
//     ctx.status = 400;
//     ctx.body = 'params error';
//     return;
//   }
//   let ret = await token.smsCode(ctx.query.phone);
//   ctx.body = ret;
// }
