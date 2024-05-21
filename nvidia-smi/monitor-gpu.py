import time
import pynvml
from prettytable import PrettyTable


class GPUMonitor:
    def __init__(self) -> None:
        pynvml.nvmlInit()
        self.driver_version = pynvml.nvmlSystemGetDriverVersion()
        self.cuda_version = pynvml.nvmlSystemGetCudaDriverVersion()
        self.num_device = pynvml.nvmlDeviceGetCount()

    def get_current_info(self) -> PrettyTable:
        info = f"Driver Version:{self.driver_version}" + " " * 12
        info += f"CUDA Version:{self.cuda_version}"
        table = PrettyTable(
            ["Device ID", "Device Name", "Temp", "Used/Total Mem(MB)", "GPU Util"],
            title=info,
        )

        for idx in range(self.num_device):
            handle = pynvml.nvmlDeviceGetHandleByIndex(idx)
            device_name = pynvml.nvmlDeviceGetName(handle)
            mem_info = pynvml.nvmlDeviceGetMemoryInfo(handle)
            total_mem = int(mem_info.total / 1024 / 1024)
            used_mem = int(mem_info.used / 1024 / 1024)
            util = pynvml.nvmlDeviceGetUtilizationRates(handle).gpu
            temp = pynvml.nvmlDeviceGetTemperature(handle, 0)
            table.add_row(
                [idx, device_name, f"{temp}C", f"{used_mem}/{total_mem}", f"{util}%"]
            )

        return table


def monitor_script():
    import argparse

    parser = argparse.ArgumentParser(description="Monitor GPU Tools", add_help=True)
    parser.add_argument(
        "-n",
        "--interval",
        type=float,
        default=1.0,
        help="seconds to wait between updates",
    )
    args = parser.parse_args()

    interval = args.interval
    print(f"update interval: {interval:.1f}s")
    monitor = GPUMonitor()

    try:
        while True:
            table = monitor.get_current_info()
            rows = str(table).count("\n") + 1
            print(table)
            time.sleep(1)

            print(f"\033[{rows}A", end="")
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    monitor_script()
