# Smart Rain Detection and Prediction System using AI & IoT

Production-ready starter project integrating IoT simulation, Node.js API, Python ML models, PostgreSQL schema, and React dashboard.

## 1) Folder Structure

```text
smart-rain-ai-iot-system/
├── backend/
│   ├── src/
│   │   ├── config/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── routes/
│   │   ├── services/
│   │   └── server.js
│   ├── scripts/
│   └── Dockerfile
├── ai/
│   ├── data/
│   ├── models/
│   ├── tests/
│   ├── train.py
│   └── inference.py
├── frontend/
│   ├── src/
│   ├── public/
│   └── Dockerfile
├── database/
│   └── schema.sql
├── docs/
│   └── API.md
├── iot-simulator/
│   └── send_mock_data.js
├── docker-compose.yml
└── mock-data/
    └── sensor_payload.json
```

## 2) Quick Start with Docker (Recommended)

> This is the recommended path to run everything with one command.

```bash
docker compose up --build
```

Services:
- Frontend: `http://localhost:3000`
- Backend API: `http://localhost:4000/api/v1`
- PostgreSQL: `localhost:5432`

Notes:
- DB schema auto-runs from `database/schema.sql`.
- Backend startup script auto-trains AI models if model files do not exist.

Stop all services:

```bash
docker compose down
```

## 3) Local Setup (Manual)

### Database
1. Create PostgreSQL database named `smart_rain`.
2. Run:
   ```bash
   psql -U postgres -d smart_rain -f database/schema.sql
   ```

### AI Model Training
```bash
cd ai
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python train.py
```

### Backend
```bash
cd backend
cp .env.example .env
npm install
npm run dev
```

### Frontend
```bash
cd frontend
npm install
npm start
```

## 4) Backend Environment Variables

Create `backend/.env`:

```env
PORT=4000
NODE_ENV=development
JWT_SECRET=super-secret-key
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=smart_rain
PYTHON_EXECUTABLE=python3
```

## 5) Feature Coverage
- Real-time sensor ingestion API with validation.
- AI rain detection (classification) + rainfall forecast (1h/2h/3h).
- Dynamic threshold from DB (`system_settings`) — no hardcoded threshold.
- Role-based access (`admin`, `user`) via JWT.
- Automation simulation logs when rain risk is high.
- React dashboard with real-time polling and graphs.
- IoT mock data simulator script.
- Unit tests for API and AI inference.

## 6) Development Strategy (Simple First)
1. Run DB + backend + `/sensors/ingest`.
2. Train and connect AI model.
3. Start dashboard.
4. Add simulator + automation.
5. Expand to hardware (ESP32) and notifications (Firebase/Blynk).

## 7) Deployment Path
- Backend: Render / Railway
- Frontend: Vercel
- DB: Supabase / Neon

See full endpoint details in `docs/API.md`.
