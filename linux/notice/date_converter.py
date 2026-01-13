#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from zhdate import ZhDate
import datetime
import sys

# 农历转阳历
def lunar_to_solar(year, month, day, is_leap=False):
    lunar = ZhDate(year, month, day, is_leap) 
    return lunar.to_datetime().date()

# 阳历转农历
def solar_to_lunar(year, month, day):
    solar_datetime = datetime.datetime(year, month, day)
    return ZhDate.from_datetime(solar_datetime)

def main():
    if len(sys.argv) < 4:
        print("Usage:")
        print("  阳历转农历: ./date_converter.py <solar_year> <solar_month> <solar_day>")
        print("  农历转阳历: ./date_converter.py <lunar_year> <lunar_month> <lunar_day> [is_leap]")
        print("    is_leap: 0(表示不闰月), 1(表示闰月)")
        sys.exit(1)

    try:
        year = int(sys.argv[1])
        month = int(sys.argv[2])
        day = int(sys.argv[3])
    except ValueError:
        print("Error: Year, month, and day must be integers.", file=sys.stderr)
        sys.exit(1)

    # 判断是农历转阳历（有第4个参数）还是阳历转农历（只有3个参数）
    if len(sys.argv) == 5:
        # 农历转阳历
        is_leap = bool(int(sys.argv[4])) if len(sys.argv) > 4 else False
        #is_leap = bool(int(sys.argv[4]))
        try:
            solar = lunar_to_solar(year, month, day, is_leap)
            leap_str = "闰" if is_leap else ""
            print(f"农历 {year} 年 {leap_str}{month} 月 {day} 日 对应阳历: {solar}")
        except Exception as e:
            print("农历转阳历失败:", e, file=sys.stderr)
            sys.exit(1)

    elif len(sys.argv) == 4:
        # 阳历转农历
        try:
            lunar = solar_to_lunar(year, month, day)

            # 处理闰月（zhdate v1.0 中，闰月的 lunar_month > 12）
            if lunar.lunar_month > 12:
                leap_str = "闰"
                real_month = lunar.lunar_month - 12
            else:
                leap_str = ""
                real_month = lunar.lunar_month

            print(f"阳历 {year}-{month:02d}-{day:02d} 对应农历: {lunar.lunar_year} 年 {leap_str}{real_month} 月 {lunar.lunar_day} 日")

        except Exception as e:
            print("阳历转农历失败:", e, file=sys.stderr)
            sys.exit(1)

    else:
        print("错误: 参数数量不正确。", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()

