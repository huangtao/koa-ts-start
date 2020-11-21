import { Context } from 'koa';

export const register = async (ctx: Context) => {
  const { username, pwd, phone, token } = ctx.request.body;
  let res = {
    flag: -1,
    msg: ''
  };
  if (!username || !pwd || !phone || !token) {
    ctx.status = 400;
    res.msg = 'params error';
    ctx.body = res;
    return;
  }
  let sql = `SET @name='${username}';SET @password='${pwd}';SET @phone='${phone}';`
  sql += `SET @token='${token}';SET @ret=0;`;
  sql += "CALL cp_register(@name,@password,@phone,@token,@ret);SELECT @ret AS ret";
  try {
    let dbResults = await ctx.db.query(sql);
    let cpRet = -1;
    // 获取返回值
    for (let i = dbResults.fields.length - 1; i >= 0; i--) {
      if (dbResults.fields[i] && dbResults.fields[i][0].name == 'ret') {
        cpRet = dbResults.results[i][0].ret;
        break;
      }
    }
    res.flag = cpRet;
    ctx.body = res;
    return;
  } catch (err) {
    ctx.status = 400;
    res.msg = 'failed!';
    ctx.body = res;
    return;
  }
}

export const login = async (ctx: Context) => {

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
