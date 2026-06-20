#!/usr/bin/env python3
# Запуск бэкенда:  python start.py
# Или: uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

import uvicorn
from dotenv import load_dotenv
import os

load_dotenv()

if __name__ == "__main__":
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("app.main:app", host=host, port=port, reload=True)
