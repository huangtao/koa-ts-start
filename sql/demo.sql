--
-- 平台sql脚本(MySQL)
-- huangtao117@yeah.net
--
-- 1.安装好MySQL后建立数据库
-- CREATE DATABASE demo
-- 2.命令行管理工具连接demo
-- mysql -h host -u user -p demo
-- 3.导入脚本
-- 直接导入:
-- mysql < demo.sql
-- Windows: mysql -e "demo.sql"
-- mysql连接后导入:
-- mysql> source demo.sql;
-- 4.导入成功后可以查看表和函数
-- SHOW TABLES;
-- 5.退出
-- QUIT
--
/*
 * 这个是多行注释
 * 单行注释用--(后面必须紧接一个空格)
 */

USE demo;

--
-- 表
--

-- 用户表
CREATE TABLE IF NOT EXISTS res_users(
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,    -- 平台数字账号
    active TINYINT DEFAULT 1,                   -- 是否激活
    login_name VARCHAR(255) NOT NULL,           -- 登录账号
    login_password TEXT,                        -- 登录密码
    company_id INT DEFAULT 0,                   -- 公司编号
    create_date DATETIME DEFAULT NOW(),         -- 创建时间
    phone VARCHAR(128) NOT NULL,                -- 绑定手机
    x_signature TEXT,                           -- 验证码,签名
    attributes JSON,                            -- json数据
    PRIMARY KEY (id),
    UNIQUE (login_name)
) AUTO_INCREMENT=10000;

-- 公司表
CREATE TABLE IF NOT EXISTS res_company(
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,    -- 公司编号
    x_name VARCHAR(255) NOT NULL,               -- 公司名称
    pay_point INT DEFAULT 0,                    -- 支付点
    create_date DATETIME DEFAULT NOW(),         -- 创建时间
    email VARCHAR(255),                         -- 邮件地址
    phone VARCHAR(128),                         -- 联系电话
    attributes JSON,                            -- json数据
    PRIMARY KEY (id),
    UNIQUE (x_name)
);

-- 短信登陆token
CREATE TABLE IF NOT EXISTS sms_token(
    phone VARCHAR(64) NOT NULL,     -- 电话号码
    token VARCHAR(64) NOT NULL,     -- 验证码
    add_time DATETIME NOT NULL,     -- 加入时间
    expired_time DATETIME NOT NULL, -- 过期时间
    send_count SMALLINT DEFAULT 0,  -- 已发送次数
    PRIMARY KEY (phone)
);

/**************************************************************************************/
--
-- 存储过程
--

-- MySQL默认语句结束为(;)，存储过程语句也需要;来结束
-- 为了避免冲突将MySQL结束符设置为&&
DELIMITER &&

--
-- 测试
--
DROP PROCEDURE IF EXISTS cp_test&&
CREATE PROCEDURE cp_test(IN a INT, IN b INT, OUT s INT)
BEGIN
    SET s = a + b;
END&&

--
-- 初始化基本数据
--
DROP PROCEDURE IF EXISTS cp_init&&
CREATE PROCEDURE cp_init()
BEGIN
    -- 我们需要开启定时任务
    SET GLOBAL event_scheduler = 1;
    -- 初始数据
END&&

-- 刷新短信验证码
DROP PROCEDURE IF EXISTS cp_sms_update&&
CREATE PROCEDURE cp_sms_update(IN _phone VARCHAR(64), IN _token VARCHAR(64), OUT ret INT)
proc_label:BEGIN
    DECLARE tempToken VARCHAR(64);
    DECLARE _sendCount SMALLINT;

    SET ret = 0;
    SELECT token,send_count INTO tempToken,_sendCount FROM sms_token WHERE phone=_phone;
    IF FOUND_ROWS() = 0 THEN
        INSERT INTO sms_token(phone,token,add_time,expired_time)
            VALUES(_phone,_token,NOW(),DATE_ADD(NOW(), INTERVAL 30 MINUTE));
        LEAVE proc_label;
    END IF;
    IF _sendCount >= 5 THEN
        -- 浪费我的短信费
        SET ret = -1;
        LEAVE proc_label;
    END IF;
    UPDATE sms_token SET token=_token,send_count=send_count+1 WHERE phone=_phone;
END&&

-- 用户注册
DROP PROCEDURE IF EXISTS cp_register&&
CREATE PROCEDURE cp_register(IN _name VARCHAR(255),_password TEXT,_phone VARCHAR(64),IN _token VARCHAR(64),OUT ret INT)
proc_label:BEGIN
    DECLARE tempToken VARCHAR(64);
    DECLARE _companyid INT;

    SET ret = -1;
    -- 是否已经有这个用户
    SELECT id FROM res_users WHERE login_name=_name OR phone=_phone;
    IF FOUND_ROWS() != 0 THEN
        SET ret = -1;
        LEAVE proc_label;
    END IF;
    -- 验证码
    SELECT token INTO tempToken FROM sms_token WHERE phone=_phone;
    IF FOUND_ROWS() = 0 THEN
        -- 重新获取验证码
        SET ret = -2;
        LEAVE proc_label;
    END IF;
    IF STRCMP(tempToken, _token) != 0 THEN
        -- 验证码不对
        SET ret = -3;
        LEAVE proc_label;
    END IF;
    DELETE FROM sms_token WHERE phone=_phone;
    -- 创建用户
    INSERT INTO res_users(login_name,login_password,phone) VALUES(_name,_password,_phone);
    SET ret = 0;
END&&

-- 用户登录
DROP PROCEDURE IF EXISTS cp_login&&
CREATE PROCEDURE cp_login(IN _name VARCHAR(255), IN _password TEXT, OUT ret INT)
proc_label:BEGIN
    DECLARE _id INT;
    DECLARE _active TINYINT;
    DECLARE _companyid INT;
    DECLARE _ename VARCHAR(128);
    DECLARE _max_member INT;
    DECLARE _expired_date DATETIME;
    DECLARE _dbip VARCHAR(255);
    DECLARE _dbport VARCHAR(64);
    DECLARE _dbuser VARCHAR(128);
    DECLARE _dbpwd VARCHAR(128);
    DECLARE _dbname VARCHAR(128);
    DECLARE _attr JSON;

    SET ret = -1;
    SELECT id,active,company_id,IFNULL(attributes,'{}')
        INTO _id,_active,_companyid,_attr FROM res_users
        WHERE login_name=_name AND login_password=_password;
    IF FOUND_ROWS() = 0 THEN
        -- 没有这个用户
        SET ret = -1;
        LEAVE proc_label;
    END IF;
    IF _active != 1 THEN
        -- 冻结
        SET ret = -2;
        LEAVE proc_label;
    END IF;
    SET ret = 0;
    SELECT _id,_companyid,_attr;
END&&

/******************************************************************************************************/
-- 定时任务

-- 清理过期短信验证码任务
DROP EVENT IF EXISTS e_clear_token&&
CREATE EVENT e_clear_token
    ON SCHEDULE EVERY 30 MINUTE STARTS '2020-01-01 06:00:00'
    ON COMPLETION PRESERVE
    ENABLE
    DO
    BEGIN
        DECLARE v_date DATE;

        SET v_date = SUBDATE(DATE(NOW()), INTERVAL 10000 MINUTE);
        -- 删除超过30分钟的短信验证码
        DELETE FROM sms_token WHERE DATE(expired_time)<v_date;
    END&&

-- 恢复结束符
DELIMITER ;

-- 手动调用初始化存储过程
-- call cp_init();
