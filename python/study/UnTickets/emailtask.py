import copy
import smtplib
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.image import MIMEImage
from email.header import Header
from email.utils import parseaddr, formataddr
from email.mime.base import MIMEBase
from email import encoders


class EmaiInfo:
    def __init__(self, sender, receivers, ccs, subject, mainbody, attachments):
        self.sender = sender
        self.receivers = receivers
        self.ccs = ccs
        self.subject = subject
        self.mainbody = mainbody
        self.attachments = attachments


class EmailUser:
    def __init__(self, user_email, user_name):
        self.user_email = user_email
        self.user_name = user_name

    def __repr__(self):
        return repr((self.user_email))


def _format_addr(s):
    name, addr = parseaddr(s)
    return formataddr((Header(name, 'utf-8').encode(), addr))


def RecordSegmentation(oldRecords):
    #一次排序
    #根据传入的对象放置到匿名函数中，并按对象的consultant_email(测试顾问邮箱)进行排序最终返回
    sortedRecords = sorted(oldRecords, key=lambda r: r.consultant_email)
    mark_consultant_email = "init"
    temp_records = []
    resultRecord = []
    #二次排序
    for record in sortedRecords:   
        #循环遍历经过"测试顾问邮箱"排序的对象，如果第一批相同邮箱先放至temp_records列表，当第二批邮箱不一样时先将temp_records列表的值复制到resultRecord列表中，然后清除temp_records列表并向其中添加第二批邮箱，如此反复
        if mark_consultant_email == record.consultant_email:
            temp_records.append(record)
        if mark_consultant_email != record.consultant_email:
            if len(temp_records) > 0:
                resultRecord.append(copy.deepcopy(temp_records))
            temp_records.clear()
            temp_records.append(record)
            mark_consultant_email = record.consultant_email
    #最后一次添加temp_records列表的值到resultRecord列表中
    if len(temp_records) > 0:
        resultRecord.append(copy.deepcopy(temp_records))
    #返回按邮箱排序的对象
    return resultRecord


def ConvertToEmailInfo(oriInfo, sender_email, sender_name, subject, is_cc_to_self):
    result_email_info = []
    for ori in oriInfo:
        ori_sender = EmailUser(sender_email, sender_name)
        ori_receivers = []
        ori_ccs = []
        ori_subject = subject
        ori_mainbody = ""
        ori_attachments = []
        # 加收件人
        ori_receivers.append(EmailUser(ori[0].consultant_email, ori[0].consultant_cname))
        # 加抄送人
        ori_ccs.append(EmailUser(ori[0].manager_email, ori[0].manager_name))
        # 加入自己的邮件
        if is_cc_to_self:
            ori_ccs.append(EmailUser(sender_email, sender_name))
        # 生成邮件主体
        ori_mainbody = "<html><body>Dear %s：<br>&nbsp;&nbsp;&nbsp;&nbsp;附件是%s，请查收。谢谢</body></html>" % (
        ori[0].consultant_ename.capitalize(), subject)
        # 加附件地址
        for attach in ori:
            ori_attachments.append(attach.ucFileFullName)

        consultant_email_info = EmaiInfo(ori_sender, ori_receivers, ori_ccs, ori_subject, ori_mainbody, ori_attachments)
        result_email_info.append(consultant_email_info)
    return result_email_info


def SendMail(sendEmailInfo, mail_host, mail_user, mail_password):
    msg = MIMEMultipart()
    #取出"EmaiInfo对象"中"属性sender"的"对象值user_name"
    msg['From'] = _format_addr('%s <%s>' % (sendEmailInfo.sender.user_name, sendEmailInfo.sender.user_email))

    msg['To'] = ""
    for to in sendEmailInfo.receivers:
        msg['To'] += _format_addr('%s <%s>;' % (to.user_name, to.user_email))
    msg['To'] = msg['To'][:-1]

    msg['Cc'] = ""
    for cc in sendEmailInfo.ccs:
        msg['Cc'] += _format_addr('%s <%s>;' % (cc.user_name, cc.user_email))
    msg['Cc'] = msg['Cc'][:-1]

    msg['Subject'] = Header(sendEmailInfo.subject, 'utf-8').encode()

    msg.attach(MIMEText(sendEmailInfo.mainbody, 'html', 'utf-8'))

    for att in sendEmailInfo.attachments:
        cid = 0
        with open(att, 'rb') as f:
            # 设置附件的MIME和文件名，这里是octet-stream类型（废弃），子类型为vnd.ms-excel:
            mime = MIMEBase('application', 'vnd.ms-excel', filename=os.path.basename(att))
            # 加上必要的头信息:
            mime.add_header('Content-Disposition', 'attachment', filename=os.path.basename(att))
            mime.add_header('Content-ID', '<%s>' % str(cid))
            mime.add_header('X-Attachment-Id', str(cid))
            # 把附件的内容读进来:
            mime.set_payload(f.read())
            # 用Base64编码:
            encoders.encode_base64(mime)
            # 添加到MIMEMultipart:
            msg.attach(mime)
            cid += 1

    msgReceivers = []
    for msgR in sendEmailInfo.receivers:
        msgReceivers.append(msgR.user_email)
    for msgC in sendEmailInfo.ccs:
        msgReceivers.append(msgC.user_email)
    server = smtplib.SMTP(mail_host, 25)
    server.login(mail_user, mail_password)
    server.sendmail(sendEmailInfo.sender.user_email, msgReceivers, msg.as_string())
    server.quit()

    return True
