import xlrd
import xlwt
from xlutils.copy import copy


def ButifyExcel_Single(file):
#打开工作薄并选择第一个sheet
    rwb = xlrd.open_workbook(file)
    table = rwb.sheet_by_index(0)
#复制打开的工作薄并选择第一个sheet
    wwb = copy(rwb)
    sht = wwb.get_sheet(0)
#初始化标题样式
    style_title = xlwt.XFStyle()
    #初始化头部样式
    style_header = xlwt.XFStyle()
    #初始化数据样式
    style_data = xlwt.XFStyle()
#创建单元格的对齐方式
    alc = xlwt.Alignment()
    # 水平居中
    alc.horz = xlwt.Alignment.HORZ_CENTER
    # 垂直居中
    alc.vert = xlwt.Alignment.VERT_CENTER
# 为标题创建字体
    font_title = xlwt.Font()
    # 黑体
    font_title.bold = True
    # 字体高宽度
    font_title.height = 20 * 14
# 为头部创建字体
    font_header = xlwt.Font()
    font_header.bold = True
    font_header.height = 20 * 10
# 为数据创建字体
    font_data = xlwt.Font()
    font_data.height = 20 * 10
# 创建边框对象
    borders = xlwt.Borders()
    #设置上下左右边框的样式
    borders.left = 1
    borders.right = 1
    borders.top = 1
    borders.bottom = 1
#设置标题字体，对齐方式
    style_title.font = font_title
    style_title.alignment = alc
#设置头部字体，对齐方式
    style_header.font = font_header
    style_header.alignment = alc
    style_header.borders = borders
#设置数据字体，对齐方式
    style_data.font = font_data
    style_data.alignment = alc
    style_data.borders = borders

# 获取工作表中有效行数
    for i in range(1, table.nrows):
    # 获取工作表中有效列数
        for j in range(table.ncols):
            if j < 5:
                # python读取是从0，0开始的，第一个参数代表行，第二个参数是列，第三个参数是内容，第四个参数是格式
                sht.write(i, j, table.row_values(i)[j], style_data if i != 1 else style_header)
            elif j == 5:
                continue
            elif j < 8:
                sht.write(i, j - 1, table.row_values(i)[j], style_data if i != 1 else style_header)
            elif j == 8 or j == 9:
                continue
            elif j < 12:
                sht.write(i, j - 3, table.row_values(i)[j], style_data if i != 1 else style_header)
            elif j == 12 or j == 13:
                continue
            else:
                sht.write(i, j - 5, table.row_values(i)[j], style_data if i != 1 else style_header)
            for k in range(13, 18):
                sht.write(i, k, '')
    #合并列和行，(行，行，列，列，内容，样式风格)，'合并从第1行到第1行，第1列到第13列'，并将原始sheet值赋值结副本sheet
    sht.write_merge(0, 0, 0, 12, table.row_values(0)[0], style_title)
#配置列宽
    for c in range(table.ncols):
        #获取原始sheet中的第0列、从第一行到总有效行数的数据
        col_value_list = table.col_values(c, 1, table.nrows)
        #设定gbk格式+4个字符的列宽
        col_width = max(len(x.encode('gbk')) for x in col_value_list) + 4
        if c < 5:
            sht.col(c).width = 256 * col_width
        elif c == 5:
            continue
        elif c < 8:
            sht.col(c - 1).width = 256 * col_width
        elif c == 8 or c == 9:
            continue
        elif c < 12:
            sht.col(c - 3).width = 256 * col_width
        elif c == 12 or c == 13:
            continue
        else:
            sht.col(c - 5).width = 256 * col_width
#保存副本数据到原始数据中
    wwb.save(file)
