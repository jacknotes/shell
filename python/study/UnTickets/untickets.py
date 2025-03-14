import datetime
import time
import os
import sys
import shutil
import argparse
import string

import webdata
import dataclean
import datarepo
import emailtask

ADDRESS_PASSPORT = 'passport.domain.com'
USERNAME = 'user'
PASSWORD = 'password'
ADDRESS_TICKET = 'ticketproduct.domain.com'
ADDR_LoginCheckIdnumberAndName = '/Home/LoginCheckIdnumberAndName'
ADDR_ManualExecutionUnusedTickets = '/FlightUnusedTickets/ManualExecutionUnusedTickets'
ADDR_ExecutionUnusedTicketsStatus = '/FlightUnusedTickets/ExecutionUnusedTicketsStatus'
ADDR_ExportExcel = '/FlightUnusedTickets/ExportExcel'

'''
$uclist='020880','018928','017064','021414','021212','021127'
foreach($uc in $uclist){ python untickets.py -s $uc 2020-12-03 2021-12-02; Start-Sleep -Seconds 10}
'''



# STATUS_OPEN_FOR_USE = r'["OPEN FOR USE","UNKNOWN"]'
STATUS_OPEN_FOR_USE = r'["OPEN FOR USE"]'
DAY_DELTA = 70

DB_FILE = 'UC.sqlite3'
DB_TABLE = "companys"

IS_CC_TO_SELF = True
SENDER_EMAIL = "username@domain.com"
SENDER_NAME = "用户名称"
MAIL_HOST = 'smtp.qiye.163.com'
MAIL_USER = 'username@domain.com'
MAIL_PASSWORD = 'password_for_email'


def formatDate(date):
    # 将datetime格式转化为 ”2021-03-03“ 这种形式的格式
    return date.strftime("%Y-%m-%d")


def sleeptime(count):
    #每条3秒
    return int(count * 3)
    
    

#custom create by 202112021603
def initBackupExcelDir(BackupExcelPath):
    try:
        if not os.path.exists(BackupExcelPath):
            print('[Info]: Create Backup Excel Directory {}.'.format(BackupExcelPath))
            os.mkdir(BackupExcelPath)
    except:
        print('[Error]: create Backup Excel Directory {} Fault. Exit Program.'.format(BackupExcelPath))
        sys.exit(0)
        
#custom create by 202112022016
def BackupExcelFile(excelpath,BackupExcelPath):
    try:
        if not os.path.exists(excelpath):
            print('[Info]: No such directory of %s.' % (excelpath))
            print('[Info]: Create Excel Directory %s.' % (excelpath))
            os.mkdir(excelpath)
        filelist=os.listdir(excelpath)
        for i in filelist:
            #print('i:',i)
            shutil.move(os.path.join(excelpath,i),os.path.join(BackupExcelPath, i))  
    except:
        print('[Error]: Backup Excel File Failt.')
 



def getUnTicketsSingle(ucno, datefrom, dateto, takeofffrom, takeoffto, status, excelDir):
    appLoginInfo = webdata.LoginInfo(USERNAME, PASSWORD, ADDRESS_PASSPORT + ADDR_LoginCheckIdnumberAndName)
    #获取cookie
    tCookies = webdata.CookieGen(appLoginInfo)
    # 旧逻辑：未使用票号出票日期重跑
    # 新逻辑：未使用票号起飞日期重跑
    appMEUTInfo = webdata.TicketsInfoMEU(ADDRESS_TICKET + ADDR_ManualExecutionUnusedTickets, tCookies,
                                         ucno, datefrom, dateto)
    
    countTicketsFirst = int(webdata.ManualExecutionUnusedTickets(appMEUTInfo))
    if countTicketsFirst == -1:
        print('[Error]: ManualExecutionUnusedTickets')
        print('[Error]: Get {}\'s Unused Tickets Fault. Exit Program.'.format(ucno))
        sys.exit(0)
    #未使用票号起飞日期再次重跑
    appEUTSInfo = webdata.TicketsInfoEUTS(ADDRESS_TICKET + ADDR_ExecutionUnusedTicketsStatus, tCookies,
                                          ucno, takeofffrom, takeoffto, status)

    countTickets = int(webdata.ExecutionUnusedTicketsStatus(appEUTSInfo))
    if countTickets == -1:
        print('[Error]: ExecutionUnusedTicketsStatus')
        print('[Error]: Get {}\'s Unused Tickets Fault. Exit Program.'.format(ucno))
        sys.exit(0)
    # 由于跑单个票号时常有延迟，所以我将条数X3,增加延迟拉取时间
    seconds = sleeptime(countTicketsFirst+countTickets)
    print('[Info]: firstCount: {}, secondCount: {}, CountSeconds: {}'.format(countTicketsFirst, countTickets, seconds))
    print('[Info]: Now is {} . Please waiting {} seconds.'.format(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                                                                  str(seconds)))
    time.sleep(seconds)
    #导出excel并格式化excel
    appEEInfo = webdata.TicketsInfoEE(ADDRESS_TICKET + ADDR_ExportExcel, tCookies, excelDir,
                                      ucno, takeofffrom, takeoffto, status)

    if webdata.ExportExcel(appEEInfo):
        return True
    else:
        print('[Error]: ExportExcel')
        print('[Error]: Get {}\'s Unused Tickets Fault. Exit Program.'.format(ucno))
        sys.exit(0)


def getUnTicketsMulti(ucnolist, datefrom, dateto, takeofffrom, takeoffto, status, excelDir):
    # 根据uc号码的list，批量获取未使用票号的excel
    multi_login_info = webdata.LoginInfo(USERNAME, PASSWORD, ADDRESS_PASSPORT + ADDR_LoginCheckIdnumberAndName)
    tcookies = webdata.CookieGen(multi_login_info)

    tickets_amount = 0
    #成功的UC列表
    uclist = []

    #### 如时间太长，第二次运行时，可跳过初跑和重跑，直接拉取excel
    # 批量初跑和重跑逻辑
    for ucno in ucnolist:
        time.sleep(1)
        multi_meut_info = webdata.TicketsInfoMEU(ADDRESS_TICKET + ADDR_ManualExecutionUnusedTickets, tcookies,
                                                 ucno, datefrom, dateto)
        count_tickets_first = int(webdata.ManualExecutionUnusedTickets(multi_meut_info))
        if count_tickets_first == -1:
            print('[Error]: ManualExecutionUnusedTickets. UC number: {}'.format(ucno))
            continue
        time.sleep(2)
        multi_euts_info = webdata.TicketsInfoEUTS(ADDRESS_TICKET + ADDR_ExecutionUnusedTicketsStatus, tcookies,
                                                  ucno, takeofffrom, takeoffto, status)
        count_tickets = int(webdata.ExecutionUnusedTicketsStatus(multi_euts_info))
        if count_tickets == -1:
            print('[Error]: ExecutionUnusedTicketsStatus. UC number: {}'.format(ucno))
            continue
        uclist.append(ucno)
        tickets_amount += count_tickets_first
        tickets_amount += count_tickets
        print('[Info]: usno: {}, first_num: {}, second_num: {}'.format(str(ucno),str(count_tickets_first),str(count_tickets)))
    # 新逻辑：对出票日期重跑和起飞日期重跑后的总记录行数*2进行睡眠等待，实际单条票2秒，sleep中3秒为单家单位拉取的时间
    seconds = int(tickets_amount * 2)
    print('[Info]: Now is {} . Please waiting {} seconds.'.format(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                                                                 str(seconds)))
    #实际进行睡眠的时间，如果时间不够可在这里增加                                                              
    time.sleep(seconds)

    ### 拉取excel
    multi_login_info = webdata.LoginInfo(USERNAME, PASSWORD, ADDRESS_PASSPORT + ADDR_LoginCheckIdnumberAndName)
    tcookies = webdata.CookieGen(multi_login_info)

    # for ucno in ucnolist:
    for ucno in uclist:
        multi_ee_info = webdata.TicketsInfoEE(ADDRESS_TICKET + ADDR_ExportExcel, tcookies, excelDir,
                                              ucno, takeofffrom, takeoffto, status)
        if not webdata.ExportExcel(multi_ee_info):
            print('[Error]: ExportExcel. UC Number: {}'.format(ucno))
        time.sleep(3)


def parse_takeofftime(takeofftime):
    # 用auto模式的参数来解析起飞时间，如202103代表：从2020-03-01到2021-02-28
    if len(takeofftime) != 6:
        print('[Error]: Parse Takeoff Time fault. Length must 6.')
        sys.exit(0)

    for n in takeofftime:
        # 如果不是0-9的字符将校验失败
        if n not in string.digits:
            print('[Error]: Parse Takeoff Time fault. Must be digits.')
            sys.exit(0)

    yearnow = datetime.datetime.now().year
    #获取传入值的年份，限定只在两年内的数据拉取
    takeoffyear = int(takeofftime[:4])
    if abs(yearnow - takeoffyear) > 1:
        print('[Error]: Parse Takeoff Time fault. Can not Parse the date 2 years beyond now.')
        sys.exit(0)

    takeoffmonth = int(takeofftime[4:])
    if takeoffmonth <= 0 or takeoffmonth >= 13:
        print('[Error]: Parse Takeoff Time fault. Month Error.')
        sys.exit(0)
    #校验年月是否大于当前年月
    if int(takeofftime) > int(str(yearnow) + str(datetime.datetime.now().strftime("%m"))):
        print('[Error]: Parse Takeoff Time fault. Can not Parse the date after now.')
        sys.exit(0)

    fromdate = '{}-{}-{}'.format(str(takeoffyear - 1), takeofftime[4:], '01')
    todate = (datetime.date(takeoffyear, takeoffmonth, 1) + datetime.timedelta(days=-1)).strftime('%Y-%m-%d')
    return fromdate, todate


def generate_subject(takeoffrange):
    return '{}到{}未使用票号'.format(takeoffrange[0], takeoffrange[1])


def butifyExcels(xlsdir,raw_excel_dir):
    for file in os.listdir(xlsdir):
        if file.endswith('.xls'):
            try:
                #加入一行复制文件备份
                print('[Info] copy file {} to {}'.format(os.path.join(xlsdir, file), raw_excel_dir + '\\raw-' + file))
                shutil.copy(os.path.join(xlsdir, file), raw_excel_dir + '\\raw-' + file)            
                #格式化excel
                dataclean.ButifyExcel_Single(os.path.join(xlsdir, file))
            except Exception as ex:
                print(ex)
                print('文件：{} 修改失败！'.format(file))


def check_ucno(ucno):
    if len(ucno) != 6:
        return False
    for n in ucno:
        if n not in string.digits:
            return False
    return True


def check_date_period(start, end):
    # 检查 start 和 end 是否是 ”2016-01-01“ 的格式
    for d in (start, end):
        if len(d) != 10:
            return False
        for n in d:
            if n not in (string.digits + '-'):
                return False
    # 检查日期是否符合逻辑
    startList = start.split('-')
    endList = end.split('-')
    now = datetime.datetime.now().strftime("%Y-%m-%d").split('-')
    for d in (len(startList), len(endList)):
        if d != 3:
            return False
    for i, s in enumerate(endList):
        if startList[i] > s:
            return False
        elif startList[i] < s:
            break
    for i, s in enumerate(endList):
        if s > now[i]:
            return False
        elif s < now[i]:
            break
    # 开始时间和结束时间差距1年以上
    if int(startList[0]) + 1 < int(endList[0]):
        return False
    # 结束时间和现在时间差距2年以上
    if int(endList[0]) + 2 < int(now[0]):
        return False
    return True


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Command Line Program for Get Unused Tickets.', add_help=True)

    group_mode = parser.add_mutually_exclusive_group(required=True)
    group_mode.add_argument('-s', '--single', dest='parserList', action='store', nargs=3,help='example: 021219 2020-11-04 2021-11-04')
    group_mode.add_argument('-c', '--csv', dest='parserList', action='store', nargs=2)
    group_mode.add_argument('-a', '--auto', dest='parserList', action='store', nargs=1,help='example: 201303，range is 20120301-20130228')

    des = parser.parse_args()

    excel_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), os.path.pardir, 'excel'))
    backup_excel_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), os.path.pardir, 'ExcelHistory'))
    raw_excel_dir=os.path.join(backup_excel_dir,'raw')
    time_now = datetime.datetime.now()
    
    #创建备份目录
    initBackupExcelDir(backup_excel_dir)
    #备份文件
    BackupExcelFile(excel_dir,backup_excel_dir)

    #创建raw格式备份目录
    if not os.path.exists(raw_excel_dir):
        os.mkdir(raw_excel_dir)
    
    #####sys.exit(0)
 

    # 模式为 single，参数有3个：UC号码、起飞日期Start、起飞日期End
    if len(des.parserList) == 3:
        if not check_ucno(des.parserList[0]):
            print('[Error]: {} number is not correct.'.format(des.parserList[0]))
            sys.exit(0)
        if not check_date_period(des.parserList[1], des.parserList[2]):
            print('[Error]: {} and {} is not correct.'.format(des.parserList[1], des.parserList[2]))
            sys.exit(0)
        getUnTicketsSingle(des.parserList[0], formatDate(time_now - datetime.timedelta(days=DAY_DELTA)),
                           formatDate(time_now),
                           des.parserList[1], des.parserList[2], STATUS_OPEN_FOR_USE, excel_dir)
        butifyExcels(excel_dir, raw_excel_dir)
        print('[Info]：导出 Excel 文件成功.')
    # 模式为 csv，参数有2个，第一个为起飞日期Start、第二个为起飞日期End
    # 或者 第一个参数为字符串 customize、第二个为绝对路径
    elif len(des.parserList) == 2:
        pass
    # 模式为 auto，参数只有一个，表示哪12个月，例如 202103 表示 2020-03-01 到 2021-02-28
    elif len(des.parserList) == 1:
        dbfile_abspath = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir, DB_FILE))
        ucnolist = datarepo.GetUCNumbers(dbfile_abspath, DB_TABLE)
        #获取拉取未使用票号起飞日期的起始时间、截止时间
        takeofftime = parse_takeofftime(des.parserList[0])
        try:
            #重跑、导出excel、格式化excel
            getUnTicketsMulti(ucnolist, formatDate(time_now - datetime.timedelta(days=DAY_DELTA)), formatDate(time_now),
                              takeofftime[0], takeofftime[1], STATUS_OPEN_FOR_USE, excel_dir)
            butifyExcels(excel_dir, raw_excel_dir)
            print('[Info]：导出 Excel 文件完毕.')
        except Exception as ex:
            print(ex)
            print('[Error]: Failed to Get Unused Tickets from List.')
            sys.exit(0)

        # print('[Debug]: exit')
        # sys.exit(1)

        # 自动发送邮件：准备
        ucFiles = []
        errorUcFiles = []
        records = []
 
        # 获取 excel_dir 变量下的所有xls文件，并将完整文件名录入ucFiles列表中
        print('[Debug]: excel_dir {}'.format(excel_dir))
        for file in os.listdir(excel_dir):
            if os.path.splitext(file)[1] == ".xls":
                ucFiles.append(os.path.join(excel_dir, file))
        # 将xls文件对应的记录写入records列表
        for ucFile in ucFiles:
            try:
                #遍历每个导出来的excel文件的完整路径，从数据库获取每个文件所属的文件路径、UC号、差旅顾问中文名、差旅顾问英文名、差旅顾问邮箱、郑州经理中文名、差旅经理邮箱并转换为一个对象，默认打印此对象输出UC号
                records.append(datarepo.GetUCExtendInfo(dbfile_abspath, DB_TABLE, ucFile))
            except:
                errorUcFiles.append(ucFile)
                print("[Warning]: ucFile {} 获取扩展信息失败".format(ucFile))
        # 根据顾问分割records列表并转为邮件要素
        # 按差旅顾问邮箱进行排序并分组追加进列表
        newRecords = emailtask.RecordSegmentation(records)
        # 获得每个差旅顾问的邮件体{包括发送人、发送姓名、接收人、抄送人、主题、主体信息、附件}，并且分隔在同一个列表中
        emailInfos = emailtask.ConvertToEmailInfo(newRecords, SENDER_EMAIL, SENDER_NAME, generate_subject(takeofftime),
                                                  IS_CC_TO_SELF)
        # 发送邮件
        for emailInfo in emailInfos:
            try:
                emailtask.SendMail(emailInfo, MAIL_HOST, MAIL_USER, MAIL_PASSWORD)
                print("[Info]:成功发送邮件给{}（{}）,附件数量为{}。".format(emailInfo.receivers[0].user_name,
                                                             emailInfo.receivers[0].user_email,
                                                             str(len(emailInfo.attachments))))
            except:
                for errorEmailattachment in emailInfo.attachments:
                    errorUcFiles.append(errorEmailattachment)
                    print(
                        "[Warning]：给{}的邮件发送失败，附件{}未发送".format(emailInfo.receivers[0].user_email, errorEmailattachment))
        if len(errorUcFiles) > 0:
            print('[Warning]: Send the following files failed:')
        for errorucfile in errorUcFiles:
            print('[Warning]: Error Uc File is {}'.format(errorucfile))
