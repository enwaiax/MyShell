#!/usr/bin/env python
# -*- coding:utf-8 -*-

# used for python3.*

import socket
import threading
import time

socket.setdefaulttimeout(3)  # 设置默认超时时间


def socket_port(ip, port, lock, open_ports):
    """
    输入IP和端口号, 扫描判断端口是否占用
    """
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            result = s.connect_ex((ip, port))
            if result == 0:
                with lock:
                    open_ports.append(port)
        except socket.error:
            pass


def ip_scan(ip, start_port=0, end_port=65535, max_threads=100):
    """
    输入IP，扫描IP的指定范围内的端口情况
    """
    print(f"开始扫描 {ip}")
    start_time = time.time()

    threads = []
    lock = threading.Lock()
    open_ports = []

    for port in range(start_port, end_port + 1):
        t = threading.Thread(target=socket_port, args=(ip, port, lock, open_ports))
        threads.append(t)
        t.start()

        # 控制最大线程数
        if len(threads) >= max_threads:
            for t in threads:
                t.join()
            threads = []

    # 等待所有线程完成
    for t in threads:
        t.join()

    end_time = time.time()
    print(f"扫描端口完成，总共用时：{end_time - start_time:.2f} 秒")

    if open_ports:
        print(f"{ip} 的开放端口: {open_ports}")
    else:
        print(f"{ip} 没有开放的端口")


if __name__ == "__main__":
    ip = input("Input the IP you want to scan: ") or "0.0.0.0"
    start_port = int(input("Input the start port (default 0): ") or 0)
    end_port = int(input("Input the end port (default 65535): ") or 65535)
    max_threads = int(input("Input the number of threads (default 100): ") or 100)
    ip_scan(ip, start_port, end_port, max_threads)
