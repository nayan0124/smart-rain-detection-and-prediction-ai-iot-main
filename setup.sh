#!/bin/bash
# Smart Rain Detection System - Setup Script
# This script sets up the entire project for local development

set -e

echo "========================================"
echo "Smart Rain Detection System - Setup"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Backend Setup
echo -e "${BLUE}[1/6] Setting up Backend...${NC}"
cd backend
npm install
echo -e "${GREEN}✓ Backend dependencies installed${NC}"
cd ..

# 2. Frontend Setup
echo ""
echo -e "${BLUE}[2/6] Setting up Frontend...${NC}"
cd frontend
npm install
echo -e "${GREEN}✓ Frontend dependencies installed${NC}"
cd ..

# 3. AI/ML Setup
echo ""
echo -e "${BLUE}[3/6] Setting up AI/ML environment...${NC}"
cd ai

# Check if Python venv exists
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate venv
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f "venv/Scripts/activate" ]; then
    source venv/Scripts/activate
fi

pip install -r requirements.txt
echo -e "${GREEN}✓ AI/ML dependencies installed${NC}"
cd ..

# 4. Environment Files
echo ""
echo -e "${BLUE}[4/6] Creating environment files...${NC}"

if [ ! -f "backend/.env" ]; then
    cp backend/.env.example backend/.env
    echo -e "${YELLOW}! Created backend/.env (Update with your credentials)${NC}"
fi

if [ ! -f "frontend/.env" ]; then
    cp frontend/.env.example frontend/.env
    echo -e "${YELLOW}! Created frontend/.env${NC}"
fi

# 5. Database Setup (Optional)
echo ""
echo -e "${BLUE}[5/6] Database setup (requires PostgreSQL)...${NC}"
echo -e "${YELLOW}! To set up database, run:${NC}"
echo -e "${YELLOW}  createdb smart_rain${NC}"
echo -e "${YELLOW}  psql -U postgres -d smart_rain -f database/schema.sql${NC}"

# 6. Train AI Models
echo ""
echo -e "${BLUE}[6/6] Training AI models...${NC}"
cd ai

# Activate venv again
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
elif [ -f "venv/Scripts/activate" ]; then
    source venv/Scripts/activate
fi

python train.py
echo -e "${GREEN}✓ AI models trained!${NC}"
cd ..

echo ""
echo -e "${GREEN}========================================"
echo "Setup Complete! ✓"
echo "========================================${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Start PostgreSQL database"
echo "2. Run backend:  cd backend && npm run dev"
echo "3. Run frontend: cd frontend && npm start"
echo "4. Open http://localhost:3000 in your browser"
echo ""
