import * as mysql from 'mysql';
import * as config from '../config.json';

const util = require('./util');

export class MysqlClient {
  private static instance: MysqlClient;
  private static pool: mysql.Pool;

  private constructor() {
    MysqlClient.initPool();
  }

  public static getInstance() {
    if (!MysqlClient.instance) {
      MysqlClient.instance = new MysqlClient();
    }
    return MysqlClient.instance;
  }

  private static initPool(): void {
    console.log('Init Mysql Client!');

    // 使用连接池提升性能
    // https://en.wikipedia.org/wiki/Connection_pool
    const cfgMysql = (config as any).mysql;
    this.pool = mysql.createPool({
      connectionLimit: 10,
      host: cfgMysql.host,
      port: cfgMysql.port,
      user: cfgMysql.user,
      password: util.uncryptPassword(cfgMysql.password),
      database: cfgMysql.db,
      supportBigNumbers: true,
      multipleStatements: true
    });

    this.pool.on('connection', (conn: mysql.PoolConnection) => {
      console.log(`Connection ${conn.threadId} connected!`);
    });

    this.pool.on('acquire', (conn: mysql.PoolConnection) => {
      console.log(`Connection ${conn.threadId} acquired!`);
    });

    this.pool.on('release', (conn: mysql.PoolConnection) => {
      console.log(`Connection ${conn.threadId} released!`);
    });

    this.pool.on('error', (err: any, client: any) => {
      console.log('idle client error', err.message, err.stack);
    });
  }

  public static getConnection(): Promise<mysql.PoolConnection> {
    let self = this;
    return new Promise((resolve, reject) => {
      self.pool.getConnection((err: mysql.MysqlError, conn: mysql.PoolConnection) => {
        if (err) {
          if (conn) conn.release();
          return reject(err);
        }
        return resolve(conn);
      });
    });
  }

  /**
   *
   * @param sql
   * @param values
   */
  public static query(sql: string, values?: any[]): Promise<any> {
    let self = this;
    if (!values) {
      values = [];
    }
    return self.getConnection()
      .then(conn => {
        return new Promise((resolve, reject) => {
          conn.query(sql, values, (err: mysql.MysqlError, results: any, fields: any[]) => {
            if (err) {
              if (conn) conn.release();
              return reject(err);
            }
            conn.release();
            let c: any = { results, fields };
            resolve(c);
          });
        });
      });
  };

  public static updateSmsToken(phone: string, token: string): Promise<any> {
    let self = this;
    return self.getConnection()
      .then(conn => {
        return new Promise((resolve, reject) => {
          let sql = "SET @phone='" + phone + "';SET @token='" + token + "';SET @ret=0;";
          sql += "CALL cp_sms_update(@phone,@token,@ret);SELECT @ret AS ret";
          conn.query(sql, (err: mysql.MysqlError, results: any, fields: any[]) => {
            if (err) {
              if (conn) conn.release();
              return reject(err);
            }
            conn.release();
            let c: any = { results, fields };
            resolve(c);
          });
        });
      });
  };

  public static login(phone: string, token: string, uid: number): Promise<any> {
    let self = this;
    return self.getConnection()
      .then(conn => {
        return new Promise((resolve, reject) => {
          let sql = "SET @phone='" + phone + "';SET @token='" + token;
          sql += "';SET @uid=" + uid + ";SET @ret=0;";
          sql += "CALL cp_login(@phone,@token,@uid,@ret);SELECT @ret AS ret";
          conn.query(sql, (err: mysql.MysqlError, results: any, fields: any[]) => {
            if (err) {
              console.log(err);
              if (conn) conn.release();
              return reject(err);
            }
            conn.release();
            let c: any = { results, fields };
            resolve(c);
          });
        });
      });
  };
}
