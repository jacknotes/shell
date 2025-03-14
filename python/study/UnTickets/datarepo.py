import os
import sqlite3


class Record:
    def __init__(self, uc_file_full_name, uc_number,
                 consultant_cname, consultant_ename, consultant_email,
                 manager_name, manager_email):
        self.ucNumber = uc_number
        self.ucFileFullName = uc_file_full_name
        self.consultant_cname = consultant_cname
        self.consultant_ename = consultant_ename
        self.consultant_email = consultant_email
        self.manager_name = manager_name
        self.manager_email = manager_email

    def __repr__(self):
        return repr(self.ucNumber)


def GetUCExtendInfo(db_file, db_table, xls_fullname):
    sql = "select * from %s where UC号码 = '%s'" % (db_table, os.path.basename(xls_fullname)[:8])
    with sqlite3.connect(db_file) as conn:
        c = conn.cursor()
        cursor = c.execute(sql)
        query_result = cursor.fetchone()
        #返回携带附件地址的列表
        result = Record(xls_fullname, query_result[1], query_result[3], query_result[4],
                        query_result[5], query_result[6], query_result[7])
    return result


def GetUCNumbers(db_file, db_table):
    sql = "select UC号码 from {}".format(db_table)
    result = []
    with sqlite3.connect(db_file) as conn:
        c = conn.cursor()
        cursor = c.execute(sql)
        query_result = cursor.fetchall()
        for r in query_result:
            result.append(r[0][2:])
    return result

