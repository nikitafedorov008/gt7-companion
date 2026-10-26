import importlib.util
import json
import unittest

spec = importlib.util.spec_from_file_location('catalogue', 'tools/fetch_gt7_cars.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class DataLiteralTest(unittest.TestCase):
    def test_strings_and_nested_values(self):
        raw = '{desc:`Line one\n"quotes",name: keep text \\`here\\``, paths:[`a\\\\b`,3,null,true],title:"GT"}'
        data = json.loads(module.to_json(raw))
        self.assertEqual(data['desc'], 'Line one\n"quotes",name: keep text `here`')
        self.assertEqual(data['paths'], ['a\\b', 3, None, True])

    def test_executable_content_rejected(self):
        for raw in ('{x:fetch(`evil`)}', '{x:`${fetch(1)}`}', '{x:1};alert(1)', '{x:1,x:2}'):
            with self.assertRaises(ValueError):
                module.to_json(raw)

    def test_bundled_coverage(self):
        with open('assets/cars/brand_central.json') as f:
            data = json.load(f)
        self.assertGreaterEqual(len(data['editions']['en']), 580)
        self.assertEqual(set(data['editions']['ru']), set(data['editions']['en']))
        for car_id, car in data['editions']['ru'].items():
            self.assertTrue(car['desc'])
            self.assertIn(car['manufacturerId'], data['brands'])
            self.assertIn(car['countryId'], data['countries'])
            self.assertGreaterEqual(len(data['gallery'][car_id]), 3)
