import unittest
import subprocess
import os

env = os.environ.copy()


class test_suit_spineapps_cases(unittest.TestCase):

    ##################################################################################################################################################
    #                                   Test case with spineapps Use case Only
    ##################################################################################################################################################
    
    def TC_001_app(self):
        env["TEST_CASE"] = "APP001"
        ret = subprocess.call("nosetests3 --nocapture -v ../functional_tests/spineapps.py:test_spineapps_cases.test_spineapps", shell=True, env=env)
        return ret
    
    def TC_002_app(self):
        env["TEST_CASE"] = "APP002"
        ret = subprocess.call("nosetests3 --nocapture -v ../functional_tests/spineapps.py:test_spineapps_cases.test_spineapps", shell=True, env=env)
        return ret
    
   


if __name__ == '__main__':
    unittest.main()