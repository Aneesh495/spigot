"""
Spigot Integration Test Suite
Executes end-to-end integration tests between Squirrel runtime, Python tools, and native bindings.
"""

import os
import subprocess
import tempfile
import unittest


class TestSpigotIntegration(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Locate project root directory
        cls.repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
        cls.sq_executable = "sq"
        cls.native_executable = os.path.join(cls.repo_root, "bin", "spigot_native")

    def test_squirrel_suite_execution(self):
        """Verify that the primary Squirrel test runner executes with zero failures."""
        runner_path = os.path.join(self.repo_root, "tests", "test_runner.nut")
        result = subprocess.run(
            [self.sq_executable, runner_path],
            cwd=self.repo_root,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, f"Squirrel test runner failed:\n{result.stderr}")
        self.assertIn("TEST SUITES PASSED SUCCESSFULLY!", result.stdout)
        self.assertIn("ZERO REGRESSIONS", result.stdout)

    def test_cli_app_help(self):
        """Verify that the CLI entrypoint displays valid command options."""
        cli_path = os.path.join(self.repo_root, "ui", "cli_app.nut")
        result = subprocess.run(
            [self.sq_executable, cli_path, "--help"],
            cwd=self.repo_root,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, f"CLI help failed:\n{result.stderr}")
        self.assertIn("Automated Liquid Handling & Assay Workstation", result.stdout)
        self.assertIn("Available Commands:", result.stdout)
        self.assertIn("benchmark", result.stdout)

    def test_cli_app_benchmark(self):
        """Verify that running the micro-benchmark command executes math and kinematics."""
        cli_path = os.path.join(self.repo_root, "ui", "cli_app.nut")
        result = subprocess.run(
            [self.sq_executable, cli_path, "benchmark"],
            cwd=self.repo_root,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, f"CLI benchmark failed:\n{result.stderr}")
        self.assertIn("Starting high-throughput simulation benchmark...", result.stdout)
        self.assertIn("BENCHMARK RESULTS", result.stdout)
        self.assertIn("PASSED (Zero errors)", result.stdout)

    def test_native_acceleration_binary(self):
        """Verify C++ native acceleration host executes if compiled."""
        if not os.path.isfile(self.native_executable):
            self.skipTest("bin/spigot_native not compiled yet.")

        test_accel_path = os.path.join(self.repo_root, "tests", "test_native_accel.nut")
        result = subprocess.run(
            [self.native_executable, test_accel_path],
            cwd=self.repo_root,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, f"Native test runner failed:\n{result.stderr}")
        self.assertIn("C++ Native Acceleration FFI Test Suite", result.stdout)
        self.assertIn("4/4 assertions passed", result.stdout)

    def test_worklist_parser_squirrel(self):
        """Verify worklist CSV parsing in Squirrel correctly loads records."""
        script_content = (
            'dofile("analysis/worklist_parser.nut");\n'
            'local parser = WorklistParser();\n'
            'local csv_data = "SourcePlate,SourceWell,DestPlate,DestWell,VolumeUL,LiquidClass\\nplate_src,A1,plate_dst,B2,15.5,Aqueous\\nplate_src,A2,plate_dst,B3,20.0,Glycerol50";\n'
            'local items = parser.parse_csv(csv_data);\n'
            'if (items.len() != 2) throw "Expected 2 items, got " + items.len();\n'
            'if (items[0].volume_ul != 15.5) throw "Expected 15.5 uL";\n'
            'if (items[1].dest_well != "B3") throw "Expected B3";\n'
            '::print("[PASS] Python-generated worklist verified in Squirrel\\n");\n'
        )

        with tempfile.NamedTemporaryFile(mode="w", suffix=".nut", delete=False) as sf:
            sf.write(script_content)
            temp_nut = sf.name

        try:
            result = subprocess.run(
                [self.sq_executable, temp_nut],
                cwd=self.repo_root,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, f"Squirrel worklist test failed:\n{result.stderr}")
            self.assertIn("[PASS] Python-generated worklist verified", result.stdout)
        finally:
            if os.path.exists(temp_nut):
                os.remove(temp_nut)


if __name__ == "__main__":
    unittest.main()
