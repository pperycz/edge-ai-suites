import os
import time
import unittest
import utils as module
import subprocess

JSONPATH = os.path.dirname(os.path.abspath(__file__)) + '/../configs/app_config.json'

class BaseAppsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.path = os.path.dirname(os.path.abspath(__file__))
        cls.industrial_edge_insights_vision_utils = module.industrial_edge_insights_vision_utils()

class test_apps_cases(BaseAppsTest):
    def test_apps(self):
        test_case = os.environ['TEST_CASE']
        key, value = self.industrial_edge_insights_vision_utils.json_reader(test_case, JSONPATH)
        self.industrial_edge_insights_vision_utils.docker_compose_up(value)
        time.sleep(5)
        self.industrial_edge_insights_vision_utils.list_pipelines()
        self.industrial_edge_insights_vision_utils.start_pipeline_and_check(value)
        time.sleep(5)
        self.industrial_edge_insights_vision_utils.container_logs_checker_dlsps(test_case,value)

    @classmethod
    def tearDownClass(cls):
        cls.industrial_edge_insights_vision_utils.stop_pipeline_and_check()
        subprocess.run("docker compose down -v", shell=True, executable='/bin/bash', cwd=cls.industrial_edge_insights_vision_utils.path + "/manufacturing-ai-suite/industrial-edge-insights-vision")
        time.sleep(5)