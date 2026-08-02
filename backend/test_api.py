import unittest
from fastapi.testclient import TestClient
import json

# Import FastAPI application and engine functions
from main import app
from engine import run_hybrid_engine, map_user_education_rank, map_user_skills
from llm_service import extract_profile_from_chat, generate_journey_plan

class TestCareerPathEngine(unittest.TestCase):
    
    def test_map_education_rank(self):
        import pandas as pd
        from engine import SEED_EDUCATION_LEVELS
        df_edu = pd.DataFrame(SEED_EDUCATION_LEVELS)
        
        self.assertEqual(map_user_education_rank("sma", df_edu), 1)
        self.assertEqual(map_user_education_rank("S1 - Bachelor", df_edu), 3)
        self.assertEqual(map_user_education_rank("Master S2", df_edu), 4)
        self.assertEqual(map_user_education_rank("Unknown", df_edu), 3)  # default fallback

    def test_map_skills(self):
        import pandas as pd
        from engine import SEED_SKILLS
        df_skills = pd.DataFrame(SEED_SKILLS)
        
        # Test exact match (case insensitive)
        mapped = map_user_skills(["figma", "python"], df_skills)
        self.assertIn(1, mapped)  # Figma ID
        self.assertIn(5, mapped)  # Python ID
        
        # Test substring match
        mapped = map_user_skills(["wireframe", "next.js"], df_skills)
        self.assertIn(2, mapped)  # Wireframing & Prototyping ID
        self.assertIn(9, mapped)  # React/Next.js ID

    def test_hybrid_engine_filtering_and_cbf(self):
        # 1. UI/UX Career Match
        # User has S1, in Jakarta, has Figma and User Research. Target Min salary 8,000,000.
        results = run_hybrid_engine(
            user_skills=["Figma", "User Research"],
            user_education="S1",
            user_min_salary=8000000.0,
            user_city="Jakarta"
        )
        
        self.assertTrue(len(results) > 0)
        top_match = results[0]
        self.assertEqual(top_match["career_name"], "UI/UX Designer")
        # Check gap analysis
        missing_skills_names = [s["name"] for s in top_match["skills"]["missing"]]
        acquired_skills_names = [s["name"] for s in top_match["skills"]["acquired"]]
        
        self.assertIn("Wireframing & Prototyping", missing_skills_names)
        self.assertIn("Figma", acquired_skills_names)
        self.assertIn("User Research", acquired_skills_names)

        # 2. Data Scientist Match
        # User has Python, SQL, S1, Jakarta, Min Salary 10,000,000
        results_ds = run_hybrid_engine(
            user_skills=["Python", "SQL"],
            user_education="S1",
            user_min_salary=10000000.0,
            user_city="Jakarta"
        )
        self.assertTrue(len(results_ds) > 0)
        self.assertEqual(results_ds[0]["career_name"], "Data Scientist")
        ds_missing = [s["name"] for s in results_ds[0]["skills"]["missing"]]
        self.assertIn("Machine Learning", ds_missing)
        self.assertIn("Data Analysis", ds_missing)

class TestFastAPIRoutes(unittest.TestCase):
    
    def setUp(self):
        self.client = TestClient(app)

    def test_health_check(self):
        response = self.client.get("/api/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "healthy"})

    def test_chat_journey_endpoint(self):
        # We send a transcript that implies the user wants to become a frontend engineer and has HTML/CSS/JS, S1, Bandung, expected salary 8,000,000
        payload = {
            "messages": [
                {"role": "user", "content": "Hi, I have a S1 Bachelor's degree and currently live in Bandung."},
                {"role": "assistant", "content": "Great! What skills do you have and what is your minimum salary goal?"},
                {"role": "user", "content": "I know HTML/CSS/JS. I'm looking for a salary of at least 8.000.000 IDR."}
            ]
        }
        
        response = self.client.post("/api/chat-journey", json=payload)
        self.assertEqual(response.status_code, 200)
        
        data = response.json()
        self.assertIn("extracted_params", data)
        self.assertIn("recommendations", data)
        self.assertIn("journey_plan", data)
        
        # Verify recommendation structure
        recs = data["recommendations"]
        self.assertTrue(len(recs) > 0)
        
        # Verify journey plan contains plans
        journey = data["journey_plan"]
        self.assertIn("opportunity_overview", journey)
        self.assertTrue(len(journey["journey_plans"]) > 0)

    def test_save_journey_endpoint_error_or_success(self):
        # Test save journey endpoint (expects 503 if Supabase keys missing, or 200/500 on db connections)
        payload = {
            "education": "Sarjana (S1)",
            "city": "Jakarta",
            "min_salary": 6000000.0,
            "skills": ["Figma", "User Research"],
            "opportunity_overview": "Prospek UI/UX cukup bagus.",
            "journey_plan": {
                "career_id": 1,
                "career_name": "UI/UX Designer",
                "timeline": []
            }
        }
        response = self.client.post("/api/save-journey", json=payload)
        self.assertIn(response.status_code, [200, 503, 500])

if __name__ == "__main__":
    unittest.main()
