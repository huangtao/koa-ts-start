import Router from 'koa-router';
import * as ctrl from '../controller/users';

const router = new Router();

// 注册
router.get('/register', ctrl.register);

// 登录
router.post('/login', ctrl.login);

export default router;
