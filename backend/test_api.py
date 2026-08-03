import unittest
from fastapi.testclient import TestClient
import json

# Import FastAPI application and engine functions
from main import app
from engine import run_hybrid_engine, map_user_education_rank, map_user_skills, SEED_EDUCATION_LEVELS, SEED_SKILLS


class TestCareerPathEngine(unittest.TestCase):

    def test_map_education_rank(self):
        import pandas as pd
        df_edu = pd.DataFrame(SEED_EDUCATION_LEVELS)

        # New schema: SMA=1, D3=3, S1/D4=4, S2=5, S3=6
        self.assertEqual(map_user_education_rank("sma", df_edu), 1)
        self.assertEqual(map_user_education_rank("smk", df_edu), 1)
        self.assertEqual(map_user_education_rank("D3", df_edu), 3)
        self.assertEqual(map_user_education_rank("S1 - Bachelor", df_edu), 4)
        self.assertEqual(map_user_education_rank("Master S2", df_edu), 5)
        self.assertEqual(map_user_education_rank("S3 Doktor", df_edu), 6)
        self.assertEqual(map_user_education_rank("Unknown", df_edu), 4)  # default fallback

    def test_map_skills(self):
        import pandas as pd
        df_skills = pd.DataFrame(SEED_SKILLS)

        # Exact match
        mapped = map_user_skills(["Python"], df_skills)
        python_id = next(r["id"] for r in SEED_SKILLS if r["skill_name"] == "Python")
        self.assertIn(python_id, mapped)

        # Figma exact
        mapped_figma = map_user_skills(["Figma"], df_skills)
        figma_id = next(r["id"] for r in SEED_SKILLS if r["skill_name"] == "Figma")
        self.assertIn(figma_id, mapped_figma)

        # Substring: "docker" → "Docker"
        mapped_docker = map_user_skills(["docker"], df_skills)
        docker_id = next(r["id"] for r in SEED_SKILLS if r["skill_name"] == "Docker")
        self.assertIn(docker_id, mapped_docker)

        # Substring: "kubernetes" → "Kubernetes (K8s)"
        mapped_k8s = map_user_skills(["kubernetes"], df_skills)
        k8s_id = next(r["id"] for r in SEED_SKILLS if "Kubernetes" in r["skill_name"])
        self.assertIn(k8s_id, mapped_k8s)

    def test_hybrid_engine_devops_match(self):
        """DevOps/Cyber skills should match DevOps Engineer or Cybersecurity Analyst."""
        results = run_hybrid_engine(
            user_skills=["Docker", "Kubernetes", "CI/CD", "Linux"],
            user_education="S1",
            user_min_salary=7000000.0,
            user_city="Jakarta"
        )
        self.assertTrue(len(results) > 0)
        top_name = results[0]["career_name"]
        devops_careers = {"DevOps Engineer", "Cloud Engineer", "Site Reliability Engineer (SRE)"}
        self.assertIn(top_name, devops_careers, f"Expected DevOps-related career, got: {top_name}")

    def test_hybrid_engine_cybersec_match(self):
        """Cybersecurity skills should rank Cybersecurity Analyst highly."""
        results = run_hybrid_engine(
            user_skills=["Network Security", "Penetration Testing"],
            user_education="S1",
            user_min_salary=5000000.0,
            user_city="Jakarta"
        )
        self.assertTrue(len(results) > 0)
        names = [r["career_name"] for r in results]
        self.assertTrue(
            any("Cyber" in n or "Penetration" in n for n in names),
            f"Expected cybersec career in results, got: {names}"
        )

    def test_hybrid_engine_multi_city(self):
        """Careers with 'Surabaya' in multi-city location_bias should appear for Surabaya users."""
        results = run_hybrid_engine(
            user_skills=["Docker", "Kubernetes"],
            user_education="S1",
            user_min_salary=5000000.0,
            user_city="Surabaya"
        )
        self.assertTrue(len(results) > 0, "Expected at least one career for Surabaya")


class TestFastAPIRoutes(unittest.TestCase):

    def setUp(self):
        self.client = TestClient(app)

    def test_health_check(self):
        response = self.client.get("/api/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "healthy"})

    def test_chat_journey_endpoint(self):
        payload = {
            "messages": [
                {"role": "user", "content": "Hi, I have an S1 Bachelor degree in Teknik Informatika and I live in Jakarta."},
                {"role": "assistant", "content": "Great! What skills do you have and what is your minimum salary goal?"},
                {"role": "user", "content": "I know Docker, Kubernetes, and CI/CD. Looking for at least 10.000.000 IDR."}
            ]
        }
        response = self.client.post("/api/chat-journey", json=payload)
        self.assertEqual(response.status_code, 200)

        data = response.json()
        self.assertIn("extracted_params", data)
        # Check if recommendations and plans are returned (which requires is_complete=True)
        # If the LLM returns is_complete=True, these keys will exist
        if data.get("is_complete"):
            self.assertIn("recommendations", data)
            self.assertIn("journey_plan", data)

    def test_save_journey_endpoint_error_or_success(self):
        payload = {
            "education": "Sarjana (S1)",
            "major": "Teknik Informatika",
            "city": "Jakarta",
            "min_salary": 6000000.0,
            "skills": ["Docker", "Kubernetes"],
            "opportunity_overview": "Prospek DevOps cukup bagus.",
            "journey_plan": {
                "career_id": 15,
                "career_name": "DevOps Engineer",
                "timeline": []
            },
            "cost_forecast": {
                "tuition_annual": 12000000.0,
                "housing_monthly": 1000000.0,
                "living_monthly": 1500000.0,
                "duration_years": 4,
                "total_cost": 72000000.0
            }
        }
        response = self.client.post("/api/save-journey", json=payload)
        self.assertIn(response.status_code, [200, 503, 500])


if __name__ == "__main__":
    unittest.main()
