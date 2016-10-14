import unittest
from app import create_app

class APITestCase(unittest.TestCase):
    def setUp(self):
        self.app = create_app()
        self.app_context = self.app.app_context()
        self.app_context.push()
        self.client = self.app.test_client()

    def tearDown(self):
        self.app_context.pop()

    def test_hello_world(self):
        response = self.client.get('/')
        self.assertTrue(response.status_code == 200)
        self.assertEqual(response.data.decode('utf-8'), 'Hello, World!')

    def test_404(self):
        response = self.client.get('/not_found')
        self.assertTrue(response.status_code == 404)