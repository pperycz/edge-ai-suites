import os
import time
import unittest
import spineapps_utils as spineapps_module
import subprocess

JSONPATH = os.path.dirname(os.path.abspath(__file__)) + '/../configs/app_config.json'

class BaseSpineappsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.path = os.path.dirname(os.path.abspath(__file__))
        cls.spineapps_utils = spineapps_module.spineapps_utils()

class test_spineapps_cases(BaseSpineappsTest):
    def test_spineapps(self):
        test_case = os.environ['TEST_CASE']
        key, value = self.spineapps_utils.json_reader(test_case, JSONPATH)
        self.spineapps_utils.docker_compose_up(value)
        time.sleep(5)
        self.spineapps_utils.list_pipelines()
        self.spineapps_utils.start_pipeline_and_check(value)
        time.sleep(5)
        self.spineapps_utils.container_logs_checker_dlsps(test_case,value)

    @classmethod
    def tearDownClass(cls):
        cls.spineapps_utils.stop_pipeline_and_check()
        subprocess.run("docker compose down -v", shell=True, executable='/bin/bash', cwd=cls.spineapps_utils.spineapps_path + "/manufacturing-ai-suite/industrial-edge-insights-vision")
        time.sleep(5)