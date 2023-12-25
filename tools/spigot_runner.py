#!/usr/bin/env python3
"""
Spigot Protocol Runner and Orchestrator
Provides high-level automation, protocol triggering, and execution profiling.
"""

import argparse
import os
import subprocess
import sys
import time


class SpigotRunner:
    def __init__(self, repo_root=None, prefer_native=True):
        if repo_root is None:
            self.repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        else:
            self.repo_root = os.path.abspath(repo_root)

        self.native_bin = os.path.join(self.repo_root, "bin", "spigot_native")
        self.sq_bin = "sq"

        if prefer_native and os.path.isfile(self.native_bin):
            self.runtime = self.native_bin
            self.runtime_type = "C++ Native Acceleration Host"
        else:
            self.runtime = self.sq_bin
            self.runtime_type = "Squirrel 3.2 Interpreter"

    def execute_script(self, script_relative_path, args=None):
        if args is None:
            args = []
        script_full_path = os.path.join(self.repo_root, script_relative_path)
        if not os.path.isfile(script_full_path):
            raise FileNotFoundError(f"Script not found: {script_full_path}")

        cmd = [self.runtime, script_full_path] + args
        start_time = time.perf_counter()
        result = subprocess.run(cmd, cwd=self.repo_root, capture_output=True, text=True)
        elapsed = time.perf_counter() - start_time

        return {
            "cmd": cmd,
            "returncode": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "elapsed_seconds": elapsed,
            "runtime": self.runtime_type,
        }

    def run_protocol(self, protocol_name):
        cli_script = "ui/cli_app.nut"
        return self.execute_script(cli_script, ["run", protocol_name])

    def inspect_deck(self):
        cli_script = "ui/cli_app.nut"
        return self.execute_script(cli_script, ["inspect"])

    def run_benchmark(self):
        cli_script = "ui/cli_app.nut"
        return self.execute_script(cli_script, ["benchmark"])

    def run_tests(self):
        test_script = "tests/test_runner.nut"
        return self.execute_script(test_script)


def main():
    parser = argparse.ArgumentParser(
        description="Spigot Protocol Runner & Workstation CLI"
    )
    parser.add_argument(
        "action",
        choices=["run", "inspect", "test", "benchmark"],
        help="Action to execute",
    )
    parser.add_argument(
        "--protocol",
        default="serial_dilution",
        help="Protocol name for 'run' action (default: serial_dilution)",
    )
    parser.add_argument(
        "--pure-squirrel",
        action="store_true",
        help="Force use of pure Squirrel interpreter over native binary",
    )

    args = parser.parse_args()
    runner = SpigotRunner(prefer_native=not args.pure_squirrel)

    print(f"Spigot Runner initialized using: {runner.runtime_type}")

    if args.action == "run":
        res = runner.run_protocol(args.protocol)
    elif args.action == "inspect":
        res = runner.inspect_deck()
    elif args.action == "test":
        res = runner.run_tests()
    elif args.action == "benchmark":
        res = runner.run_benchmark()

    print(res["stdout"])
    if res["stderr"]:
        print("STDERR:\n" + res["stderr"], file=sys.stderr)

    print(f"Execution finished in {res['elapsed_seconds']:.4f}s with status code {res['returncode']}.")
    sys.exit(res["returncode"])


if __name__ == "__main__":
    main()
