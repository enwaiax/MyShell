import logging
import sys
from enum import Enum


class LogLevel(Enum):
    DEBUG = logging.DEBUG
    INFO = logging.INFO
    WARNING = logging.WARNING
    ERROR = logging.ERROR
    CRITICAL = logging.CRITICAL


class CustomLogger:
    def __init__(self, name, log_file=None, log_level=LogLevel.INFO):
        """
        Custom logger constructor.

        Args:
            name (str): The name of the logger.
            log_file (str, optional): The path to the log file. Defaults to None.
            log_level (LogLevel, optional): The log level. Defaults to LogLevel.INFO.
        """
        self.logger = logging.getLogger(name)
        self.logger.setLevel(log_level.value)

        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(log_level.value)
        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )
        console_handler.setFormatter(formatter)
        self.logger.addHandler(console_handler)

        if log_file:
            file_handler = logging.FileHandler(log_file)
            file_handler.setLevel(logging.DEBUG)
            file_handler.setFormatter(formatter)
            self.logger.addHandler(file_handler)

    @classmethod
    def get_logger(cls, name, log_file=None, log_level=LogLevel.INFO):
        """
        Get a logger instance.

        Args:
            name (str): The name of the logger.
            log_file (str, optional): The path to the log file. Defaults to None.
            log_level (LogLevel, optional): The log level. Defaults to LogLevel.INFO.

        Returns:
            logging.Logger: The logger instance.
        """
        return cls(name, log_file, log_level).logger


if __name__ == "__main__":
    logger = CustomLogger.get_logger(__name__, "output.log")
    logger.info("This is an info message")
    logger.error("This is an error message")
