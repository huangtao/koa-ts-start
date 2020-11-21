import Router from 'koa-router';
import * as ctrl from '../controller/index';

const router = new Router();

/* GET home page. */
router.get('/', ctrl.get);

// // 请求验证码
// router.get('/sms_code', ctrl.sms);

export default router;
