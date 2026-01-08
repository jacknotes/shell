#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# curl -OL https://github.com/CutePandaSh/zhdate/archive/refs/tags/release-1.0.tar.gz; python3 -m pip install elease-1.0.tar.gz
# python3 -m pip install https://github.com/CutePandaSh/zhdate/archive/refs/tags/release-1.0.tar.gz

from zhdate import ZhDate
import sys

def lunar_to_solar(year, month, day, is_leap=False):
    # 当前版本需要显式传 leap=is_leap
    lunar = ZhDate(year, month, day, is_leap)
    return lunar.to_datetime().date()

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: ./lunar_to_solar.py <year> <month> <day> [is_leap]")
        print("  is_leap: 0 or omit = normal month, 1 = leap month")
        sys.exit(1)

    year = int(sys.argv[1])
    month = int(sys.argv[2])
    day = int(sys.argv[3])
    is_leap = bool(int(sys.argv[4])) if len(sys.argv) > 4 else False

    try:
        solar = lunar_to_solar(year, month, day, is_leap)
        leap_str = "闰" if is_leap else ""
        print(f"农历 {year} 年 {leap_str}{month} 月 {day} 日 对应阳历：{solar}")
    except Exception as e:
        print("转换失败:", e, file=sys.stderr)
        sys.exit(1)
