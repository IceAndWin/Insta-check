class AppError(Exception):
    def __init__(self, message: str, code: str = "UNKNOWN", retry_after: int | None = None):
        self.message = message
        self.code = code
        self.retry_after = retry_after
        super().__init__(message)


class LoginFailed(AppError):
    def __init__(self, message: str = "Login failed"):
        super().__init__(message, code="LOGIN_FAILED")


class ChallengeRequired(AppError):
    def __init__(self, message: str = "Instagram requires verification"):
        super().__init__(message, code="CHALLENGE_REQUIRED")


class RateLimited(AppError):
    def __init__(self, message: str = "Rate limited by Instagram", retry_after: int = 60):
        super().__init__(message, code="RATE_LIMITED", retry_after=retry_after)


class UserNotFound(AppError):
    def __init__(self, username: str):
        super().__init__(f"User '@{username}' not found", code="USER_NOT_FOUND")


class SessionExpired(AppError):
    def __init__(self):
        super().__init__("Instagram session expired", code="SESSION_EXPIRED")


class TwoFactorRequired(AppError):
    def __init__(self):
        super().__init__(
            "Two-factor authentication required. Log in on your phone first.",
            code="TWO_FACTOR_REQUIRED",
        )
