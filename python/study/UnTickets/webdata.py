import re
import json
import urllib
import os

import requests

REQUEST_HEADERS = {
    'Content-Type': r'application/x-www-form-urlencoded; charset=UTF-8',
    'X-Requested-With': 'XMLHttpRequest',
    'User-Agent': r'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:85.0) Gecko/20100101 Firefox/85.0'
}


class LoginInfo():
    def __init__(self, username, password, addr):
        self.username = username
        self.password = password
        self.addr = addr

    def __repr__(self):
        return repr(self.username)


class TicketsInfo():
    def __init__(self, address, cookiejar):
        self.address = address
        self.cookiejar = cookiejar


class TicketsInfoMEU(TicketsInfo):
    # ManualExecutionUnusedTickets 手动更新未使用票号所需信息，后面说初次重跑 把 出票日期 改为 起飞日期 重跑
    def __init__(self, address, cookiejar,
                 cmpId, takeOffStartTime, takeOffEndTime,
                 tsource='', startTime='', endTime='', unitPersonsHuman=''):
        TicketsInfo.__init__(self, address, cookiejar)
        self.cmpId = cmpId
        # startTime 和 endTime是出票日期
        self.startTime = startTime
        self.endTime = endTime
        self.tsource = tsource
        # takeOffStartTime 和 takeOffEndTime是起飞日期
        self.takeOffStartTime = takeOffStartTime
        self.takeOffEndTime = takeOffEndTime
        self.unitPersonsHuman = unitPersonsHuman


class TicketsInfoEUTS(TicketsInfo):
    # ExecutionUnusedTicketsStatus 对现有的未使用票号再次重跑所需信息，以起飞日期重跑
    def __init__(self, address, cookiejar,
                 cmpId, takeOffStartTime, takeOffEndTime, status,
                 tsource='', startTime='', endTime=''):
        TicketsInfo.__init__(self, address, cookiejar)
        self.cmpId = cmpId
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.tsource = tsource
        self.takeOffStartTime = takeOffStartTime
        self.takeOffEndTime = takeOffEndTime


class TicketsInfoEE(TicketsInfo):
    # ExportExcel 导出Excel所需信息
    # refundStatus = 1 是否退票，未退票
    # isWhite = 0 只查白名单，否
    def __init__(self, address, cookiejar,
                 outputdir,
                 cmpId, takeOffStartTime, takeOffEndTime, status,
                 refundStatus=1, isWhite=0, countryType=-1,
                 coupNo='', spareTc='', startTime='', endTime='', ticketNo='', refundStartTime='', refundEndTime='',
                 supplierSource='', passengersName='', refundLastStartTime='', refundLastEndTime=''):
        TicketsInfo.__init__(self, address, cookiejar)
        self.outputdir = outputdir
        self.cmpId = cmpId
        self.takeOffStartTime = takeOffStartTime
        self.takeOffEndTime = takeOffEndTime
        self.status = status
        self.refundStatus = refundStatus
        self.isWhite = isWhite
        self.countryType = countryType
        self.coupNo = coupNo
        self.spareTc = spareTc
        self.startTime = startTime
        self.endTime = endTime
        self.ticketNo = ticketNo
        self.refundStartTime = refundStartTime
        self.refundEndTime = refundEndTime
        self.supplierSource = supplierSource
        self.passengersName = passengersName
        self.refundLastStartTime = refundLastStartTime
        self.refundLastEndTime = refundLastEndTime


def isResponseOK(resp):
    # 判断是否返回了正确的页面数据（而不是重定向到了登录界面）
    if 'content-type' not in resp.headers.keys():
        return False
    if resp.ok and resp.headers['content-type'] == r'application/json; charset=utf-8':
        return True
    if resp.ok and resp.headers['content-type'] == r'application/vnd.ms-excel':
        return True
    return False


def parseResponseMessage(msg):
    # 解析响应数据（JSON），类似：    message "执行成功,当前影响记录数【0】条！"
    # 返回int，代表影响的记录数
    return re.split('[【|】]', msg)[1]


def genFileName(dir, id):
    filename = 'UC' + id + r'机票未使用票列表.xls'
    return os.path.join(dir, filename)


def CookieGen(login_info):
    # 成功则返回 cookiejar，失败则返回空字典
    requests.packages.urllib3.disable_warnings()
    with requests.Session() as s:
        s.headers.update(REQUEST_HEADERS)
        loginMsg = {'userIdNumber': login_info.username, 'userPwd': login_info.password}
        r = s.post("https://" + login_info.addr, verify=False, data=loginMsg)
        rCookies = {}
        if isResponseOK(r):
            cookie_Data = json.loads(r.text)['Data']
            rCookies = {
                'ASDASHHSJFSHDFHNVNHSHSBDFDSF': cookie_Data['RedisKey'],
                'hsToken': cookie_Data['Token'],
                'Token': cookie_Data['ERPToken'],
                'Emppoplist': urllib.parse.quote(cookie_Data['Funcs']),
                'Empnumber': cookie_Data['IdNumber'],
                'Empname': urllib.parse.quote(cookie_Data['IdName'])
            }
            print("[Info]:获取Cookies：" + str(json.loads(r.text)['IsSuccess']))
            return requests.utils.cookiejar_from_dict(rCookies, overwrite=True)
        else:
            print("[Error]:获取Cookies失败")
            return rCookies


def ManualExecutionUnusedTickets(infoMEUT):
    # 旧逻辑：手动更新未使用票号，只判断是否成功，不解析返回的数据
    ## 新逻辑：返回int，代表影响的记录数，如果错误返回-1
    formdata = {
        "CmpId": infoMEUT.cmpId,
        "tsource": infoMEUT.tsource,
        "StartTime": infoMEUT.startTime,
        "EndTime": infoMEUT.endTime,
        "TakeOffStartTime": infoMEUT.takeOffStartTime,
        "TakeOffEndTime": infoMEUT.takeOffEndTime,
        "UnitPersonsHuman": infoMEUT.unitPersonsHuman
    }

    with requests.Session() as s:
        s.headers.update(REQUEST_HEADERS)
        s.cookies = infoMEUT.cookiejar
        r = s.post("http://" + infoMEUT.address, data=formdata)
        if isResponseOK(r):
            data = json.loads(r.text)
            if data['success'] == True:
                return parseResponseMessage(data['message'])
            return -1
        return -1


def ExecutionUnusedTicketsStatus(infoEUTS):
    # 对现有的未使用票号再次重跑 返回int，代表影响的记录数，如果错误返回-1
    formdata = {
        "CmpId": infoEUTS.cmpId,
        "tsource": infoEUTS.tsource,
        "StartTime": infoEUTS.startTime,
        "EndTime": infoEUTS.endTime,
        "TakeOffStartTime": infoEUTS.takeOffStartTime,
        "TakeOffEndTime": infoEUTS.takeOffEndTime,
        "Status": infoEUTS.status
    }

    with requests.Session() as s:
        s.headers.update(REQUEST_HEADERS)
        s.cookies = infoEUTS.cookiejar
        r = s.post("http://" + infoEUTS.address, data=formdata)
        if isResponseOK(r):
            data = json.loads(r.text)
            if data['success'] == True:
                return parseResponseMessage(data['message'])
            return -1
        return -1


def ExportExcel(infoEE):
    # 导出Excel表格 失败则返回False
    queryParams = {
        "CoupNo": infoEE.coupNo,
        "SpareTc": infoEE.spareTc,
        "StartTime": infoEE.startTime,
        "EndTime": infoEE.endTime,
        "TicketNo": infoEE.ticketNo,
        "CountryType": infoEE.countryType,
        "TakeOffStartTime": infoEE.takeOffStartTime,
        "TakeOffEndTime": infoEE.takeOffEndTime,
        "RefundStartTime": infoEE.refundStartTime,
        "RefundEndTime": infoEE.refundEndTime,
        "RefundStatus": infoEE.refundStatus,
        "TicketStatus": infoEE.status,
        "CmpId": infoEE.cmpId,
        "SupplierSource": infoEE.supplierSource,
        "PassengersName": infoEE.passengersName,
        "isWhite": infoEE.isWhite,
        "RefundLastStartTime": infoEE.refundLastStartTime,
        "RefundLastEndTime": infoEE.refundLastEndTime
    }

    with requests.Session() as s:
        s.headers.update(REQUEST_HEADERS)
        s.cookies = infoEE.cookiejar
        r = s.get("http://" + infoEE.address, params=queryParams)
        if isResponseOK(r):
            filename = genFileName(infoEE.outputdir, infoEE.cmpId)
            with open(filename, 'wb') as f:
                f.write(r.content)
            return True
        # print('[Error]:导出EXCEL失败，CompanyID：' + infoEE.cmpId)
        return False
