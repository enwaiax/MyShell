import subprocess

from utils import CustomLogger

logger = CustomLogger.get_logger(__name__, "output.log")


class LocalRunner:
    def __init__(self, cwd=None):
        self.logger = logger
        self.cwd = cwd

    def run_command(self, cmd):
        if self.cwd:
            self.logger.info(f"cwd: {self.cwd}")

        self.logger.info(f"Running command: {cmd}")
        try:
            process = subprocess.Popen(
                cmd,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                cwd=self.cwd,
            )

            output = []
            for line in iter(process.stdout.readline, ""):
                print(line.strip())
                # self.logger.info(line.strip())
                output.append(line)

            output_result = "".join(output)

            exit_code = process.wait()
            if exit_code != 0:
                self.logger.error(f"Failed to run command {cmd}")
                self.logger.error(f"exit code: {exit_code}")
                self.logger.error(f"output: \n{output_result}")
                raise RuntimeError

            return output_result

        except (OSError, subprocess.CalledProcessError) as e:
            self.logger.exception("An error occurred while running the command.")
            raise RuntimeError("An error occurred while running the command.") from e

        except Exception as e:
            self.logger.error(e)
        finally:
            process.stdout.close()


if __name__ == "__main__":
    runner = LocalRunner()
    output = runner.run_command("docker ps")
