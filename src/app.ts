import Koa from 'koa';
import bodyParser from 'koa-bodyparser';
import session from 'koa-session';

import { MysqlClient } from './service/db';
import index from './routes/index';

const app = new Koa();

// 初始化数据库
app.context.db = MysqlClient.getInstance();

const CONFIG = {
  key: 'koa.sess',
  maxAge: 86400000
};

// 中间件
app.use(bodyParser());
app.use(session(CONFIG, app));

// 路由
app.use(index.routes()).use(index.allowedMethods());

// 错误处理
app.on('error', (err: Error, ctx: Koa.Context) => {
  console.error('server error', err, ctx);
})

export default app;
