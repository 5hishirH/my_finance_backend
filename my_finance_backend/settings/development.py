from .base import *

DEBUG = True
ALLOWED_HOSTS = ["*"]

# SQLite for local development
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}

# Extra development-only settings
INSTALLED_APPS += [
    # "django_extensions",
]

